/************************************************************************
 * @description create struct, union, array and pointer binding, and use it like ahk object
 * @author thqby
 * @date 2023/03/16
 * @version 1.0.3
 ***********************************************************************/

class ctypes {
	class struct extends Buffer {
		; The property is set to distinguish between `struct` and `union`
		static is_union := false
		; Same as msvc `__declspec(align(#))`
		static align := 0
		; By default, structs and unions are aligned the same way as the C compiler.
		; You can override this behavior by specifying a `pack` class property in the subclass definition.
		; Same as msvc instruction `#pragma pack(n)`
		static pack := A_PtrSize << 1
		; It is set to the size of the struct after initialization
		static size => 0

		/**
		 * @param {String} definition Definition of struct or union
		 * @param {String} name Name of struct or union, type can be retrieved by the name
		 * @param {Array|Object|Map|Buffer} init_vals The value used to initialize the struct or union
		 * @usage 
		 * - Call `ctypes.struct(def,name?)` to generate a type object from the struct definition.
		 * - Declare a class that inherits `ctypes.struct` and specify fields and defval(optional) static properties.
		 * @example
		 * class POINT extends ctypes.struct {
		 *   static fields := [['int','x'],['int','y']]
		 *   static defval := [10,20]  ; or {x:10,y:20}
		 * }
		 * ; Instantiate a struct, and assign a value
		 * pt1 := POINT(), pt2 := POINT([100,100])
		 * ; create a struct type
		 * pointtype := ctypes.struct('int x;int y;','PT')
		 * pt3 := pointtype(), pt4 := ctypes['PT']()
		 * ; Create and instantiate an anonymous union, and assign a value
		 * union := ctypes.struct('union{int a;short b;char c;}')({a:123456})
		 * ; Read field of union
		 * MsgBox union.a ' ' union.b ' ' union.c
		 * ; Write field of union
		 * union.a := 111
		 * @overload struct(definition, name?) => Class
		 * @return {this}
		 */
		static Call(init_vals?, *) {
			obj := super(this.size, 0)
			if init_vals := init_vals ?? this.defval
				this.assign(obj, init_vals)
			return obj
		}

		static assign(dst, val, root := 0) {
			static get_buf_size := Buffer.Prototype.GetOwnPropDesc('Size').Get
			if val is Buffer
				return DllCall('RtlMoveMemory', 'ptr', dst, 'ptr', val, 'uptr', Min(get_buf_size(val), this.size))
			if dst is Integer
				dst := this.from_ptr(dst, , root && root.__root)
			else if !(dst is this)
				throw TypeError()
			if val is Array {
				loop Min((fields := this.__fields).Length, val.Length)
					if val.Has(A_Index)
						dst.%fields[A_Index][2]% := val[A_Index]
			} else {
				for k, v in (val is Map ? val : val.OwnProps())
					dst.%k% := v
			}
		}

		/**
		 * Converts the pointer to the corresponding struct
		 * @return {this}
		 */
		static from_ptr(ptr, size := 0, root := 0) {
			static offset_ptr := 3 * A_PtrSize + 8
			if !ptr
				return 0
			NumPut('ptr', ptr, 'uptr', size || this.size, ObjPtr(obj := (Buffer.Call)(this)), offset_ptr)
			obj.DefineProp('__Delete', { call: __del }), root && obj.DefineProp('__root', { value: root })
			return obj
			__del(this) {
				try this.base.__Delete()
				NumPut('ptr', 0, ObjPtr(this), offset_ptr)
			}
		}

		/**
		 * Get the offset of the field.
		 * @param {Integer|String} field it can be 1-based field index, or a field name with a dot join
		 */
		static offset(field) {
			if field is Integer
				return this.__fields[field][3]
			fields := this.__fields, offset := 0, l := (ns := StrSplit(field, '.')).Length
			try for n in ns {
				--l
				for f in fields {
					if f[2] = n {
						offset += f[3]
						if !l
							return offset
						fields := f[1].__fields
						break
					}
				}
			}
			throw ValueError('unknown field')
		}

		/**
		 * @param {Array} Value Initializes the struct type by specifying `fields`
		 * @example
		 * class POINT extends ctypes.struct {
		 *   static fields := [['int','x'],['int','x']]
		 * }
		 * class MyStruct extends ctypes.struct {
		 * }
		 * ; `fields` can be initialized outside the class
		 * MyStruct.fields := [
		 *   ; basic type
		 *   ['int', 'a'],
		 *   ; int array
		 *   ['int', 'c[10]'], ; or `['int[10]', 'c']` or `[ctypes.array('int',10), 'c']`
		 *   ; ptr type, pointer to a utf-8 string. 'LPSTR' = ctypes.str('cp0'), 'LPWSTR' = ctypes.str('utf-16')
		 *   [ctypes.str('utf-8'), 'str'],
		 *   ; a type by defining a class, or calling `ctypes.struct()`
		 *   [POINT, 'd'],
		 *   ; Access a field of this type directly, `MyStruct().x`, it only be struct
		 *   POINT,
		 *   ; a ptr type
		 *   ['POINT*', 'e'] ; or `[ctypes.ptr(POINT),'e']`
		 * ]
		 */
		static fields {
			get => ''
			set {
				if this == ctypes.struct || (proto := this.Prototype) == ctypes.struct.Prototype
					throw ValueError('invalid base class')
				pack := this.HasOwnProp('pack') ? this.pack : ctypes.struct.pack
				if !(pack ~= '^(1|2|4|8|16)$')
					throw ValueError('expected pack to be 1, 2, 4, 8, or 16')
				if (is_union := this.is_union)
					if !this.HasOwnProp('is_union')
						throw ValueError('union cannot be used as a base class')
					else if this.Base != ctypes.struct
						throw ValueError('union cannot have base classes')
				if (align := this.align) && (1 << Integer(Log(align) / Log(2))) != align
					throw ValueError('expected align to be 2 ** n')
				names := Map(), types := Map(), names.CaseSense := types.CaseSense := false
				offset := this.size, fields := offset ? this.__fields.Clone() : [], i := fields.Length
				this.DefineProp('fields', { value: 0 }), max_align := 0
				if name := proto.__Class
					ctypes.types[name] := this
				for field in fields
					names[field[2]] := 1
				to_align := DefineProps(proto, Value, this.__max_align)
				this.DefineProp('__max_align', { value: to_align }), to_align := Max(to_align, this.align)
				this.DefineProp('size', { value: (offset + --to_align) & ~to_align })
				this.DefineProp('fields', { get: this => this.Prototype.__fields, set: (*) => 0 })
				proto.DefineProp('__fields', { value: fields }), max_align > this.align && this.DefineProp('align', { value: max_align })

				DefineProps(proto, def, max_to_align?) {
					max_tp_size := 0, offset_origin := offset
					for field in def {
						if field is Array {
							tp := field[1], field_name := field.Has(2) ? String(field[2]) : ''
							if RegExMatch(field_name, '^(\**)(\w+)(\[(\d+)\])?$', &m) && field_name != m[2] {
								loop StrLen(m[1])
									tp := ctypes.ptr(tp)
								field_name := m[2], m[3] && tp := ctypes.array(tp, Integer(m[4]))
							}
						} else tp := field, field_name := '', field := unset
						info := types.Get(tp, 0) || types[tp] := ctypes.__get_typeinfo(tp), i++
						wrapper := info.wrapper, basic_type := info.type, tp_size := info.size
						if max_to_align ?? 0 {
							to_align := info.align || Min(pack, info.pack)
							max_align := Max(max_align, info.align)
							max_to_align := Max(max_to_align, to_align)
							offset := (offset + --to_align) & ~to_align
						} else
							offset := offset_origin + field[3]
						if !basic_type && HasBase(wrapper, ctypes.struct) {
							if !wrapper.fields {
								try ctypes.types.Delete(wrapper.name)
								throw Error(wrapper.name ' is not fully defined')
							}
							if field_name == '' {
								DefineProps(proto, wrapper.__fields)
								if is_union
									max_tp_size := Max(max_tp_size, tp_size)
								else offset += tp_size
								continue
							}
						} else if field_name == ''
							field_name := String(i)
						if names.Has(field_name)
							throw PropertyError('Field already exists', , field_name)
						else if InStr(field_name, '__') = 1
							throw PropertyError('Private field cannot be defined', , field_name)
						proto.DefineProp(field_name, ctypes.__get_prop_desc(offset, basic_type, wrapper))
						names[field_name] := 1, fields.Push([wrapper || basic_type, field_name, offset])
						if is_union
							max_tp_size := Max(max_tp_size, tp_size)
						else offset += tp_size
					}
					if !IsSet(max_to_align)
						return offset := offset_origin
					return (is_union && offset += max_tp_size, max_to_align)
				}
			}
		}

		/**
		 * @param {Array|Map|Buffer} Value The value used to initialize the struct when it is instantiated
		 */
		static defval {
			get => ''
			set {
				if !this.fields
					throw Error('struct is not initialized' )
				val := Buffer(this.size), this.assign(this.from_ptr(val.Ptr, , val), Value)
				this.DefineProp('defval', { get: (*) => val })
			}
		}

		/**@param {Integer} index 1-based field index */
		__Item[index] {
			get => this.%this.__fields[index][2]%
			set => this.%this.__fields[index][2]% := Value
		}

		/**
		 * Get the offset of the field.
		 * @param {Integer|String} field it can be 1-based field index, or a field name with a dot join
		 */
		offset(field) => (ctypes.struct.offset)(this, field)

		/**
		 * Get the address of the struct or field.
		 * @param {Integer|String} field it can be 1-based index, or a field name with a dot join
		 */
		ptr(field?) {
			static get_buf_ptr := Buffer.Prototype.GetOwnPropDesc('Ptr').Get
			return get_buf_ptr(this) + (IsSet(field) && this.offset(field))
		}

		/**
		 * Get the size of the struct.
		 */
		size() {
			static get_buf_size := Buffer.Prototype.GetOwnPropDesc('Size').Get
			return get_buf_size(this)
		}

		static name => this.Prototype.__Class

		static __max_align => 1
		static __fields => this.Prototype.__fields
		static __dispose() {
			this.DefineProp('__dispose', { call: (*) => 0 })
			if !proto := this.DeleteProp('Prototype')
				return
			try this.__fields.Length := 0
			for n in [proto.OwnProps()*]
				proto.DeleteProp(n)
		}
	}

	class array extends Buffer {
		static length := 0, size := 0
		static name => this.Prototype.__Class

		/**
		 * Specify the `type` and `length` to create the zero-based array type.
		 * @param {String|Object} type A ctypes-compatible object or the registered type name
		 * @param {Integer} length An array length greater than zero
		 * @return A type object that inherits from `ctypes.array`
		 * @example
		 * intarray := ctypes.array('int', 20)
		 * arr := intarray()
		 * MsgBox arr[0] ' ' arr[1] ; ... arr[19]
		 * for v in arr
		 *   MsgBox v
		 */
		static Call(type, length) {
			info := ctypes.__get_typeinfo(type), name := info.name
			if name && obj := ctypes.types.Get(name .= '[' length ']', 0)
				return obj
			obj := { base: array := ctypes.array, Prototype: { __Class: name } }, name && ctypes.types[name] := obj
			NumPut('uint', 1, 'ptr', ObjPtrAddRef(array.Prototype), ObjPtr(proto := obj.Prototype), A_PtrSize + 4)
			proto.DefineProp('__Item', ctypes.__get_prop_desc(0, info.type, info.wrapper, ele_size := info.size))
			ObjRelease(ObjPtr(Object.Prototype)), align := info.pack, size := ele_size * length
			proto.DefineProp('length', { value: length })
			for prop in ['size', 'align', 'length']
				obj.DefineProp(prop, { value: %prop% })
			return obj
		}

		static assign(dst, val, root := 0) {
			static get_buf_size := Buffer.Prototype.GetOwnPropDesc('Size').Get
			if val is Buffer
				return DllCall('RtlMoveMemory', 'ptr', dst, 'ptr', val, 'uptr', Min(get_buf_size(val), this.size))
			if dst is Integer
				dst := this.from_ptr(dst, , root && root.__root)
			else if !(dst is this)
				throw TypeError()
			if val is Array {
				loop Min(this.Length, val.Length)
					if val.Has(A_Index)
						dst[A_Index - 1] := val[A_Index]
			} else throw TypeError()
		}

		__Enum(n) => (i := 0, l := this.Length, (&v, *) => i < l ? (v := this[i++], true) : false)
		ptr() => this.Ptr
		size() => this.Size
	}

	class ptr extends Buffer {
		static type => 'ptr'
		static name => this.Prototype.__Class

		/**
		 * Specify the `type` to create the pointer type, dereference by zero-based index
		 * @param {String|Object} type A ctypes-compatible object or the registered type name
		 * @return A type object that inherits from `ctypes.ptr`
		 * @example
		 * intpointer := ctypes.ptr('int')
		 * p := intpointer((buf := Buffer(20)).Ptr)
		 * MsgBox p[0] ' ' p[1] ; ... p[19]
		 */
		static Call(type) {
			if type = 'void'
				return 'ptr'
			info := ctypes.__get_typeinfo(type), name := info.name
			if name && obj := ctypes.types.Get(name .= '*', 0)
				return obj
			obj := { base: base := ctypes.ptr, Prototype: { __Class: name } }, name && ctypes.types[name] := obj
			NumPut('uint', 1, 'ptr', ObjPtrAddRef(base.Prototype), ObjPtr(proto := obj.Prototype), A_PtrSize + 4)
			proto.DefineProp('__Item', ctypes.__get_prop_desc(0, info.type, info.wrapper, info.size))
			ObjRelease(ObjPtr(Object.Prototype))
			return obj
		}
		static assign(dst, val := 0, *) {
			if val is Integer
				return NumPut('ptr', val, dst)
			if val is ctypes.struct
				return (NumPut('ptr', val.ptr(), dst), val)
			if HasProp(val, 'Ptr')
				return (NumPut('ptr', val.Ptr, dst), val)
			throw TypeError()
		}
		ptr() => this.Ptr
		size() => A_PtrSize
	}

	class str {
		static type := 'ptr', encoding := 'utf-16'

		/**
		 * Specify the `encoding` to create a pointer type representing the specified encoded string
		 * @param {String} encoding The source encoding. for example, `UTF-8`, `UTF-16` or `CP936`.
		 * @return A type object that inherits from `ctypes.str`
		 */
		static Call(encoding := 'utf-16') {
			if obj := ctypes.types.Get(name := 'str<' encoding '>', 0)
				return obj
			return ctypes.types[name] := { base: ctypes.str, encoding: encoding, name: name }
		}
		static assign(dst, val := 0, *) {
			if val is Integer
				return NumPut('ptr', val, dst)
			StrPut(val, _ := Buffer(StrPut(val, encoding := this.encoding)), encoding)
			return (NumPut('ptr', _.Ptr, dst), _)
		}
	}

	; Cache types that are generated by inheritance or dynamically
	static types := Map(), types.CaseSense := false
	static __New() {
		if this != ctypes
			throw Error('ctypes cannot be the base class')
		this.DeleteProp('Prototype')
		; reset class call method, calling the base class directly will have a different effect than inheriting from it
		desc := this.GetOwnPropDesc('struct'), desc.call := generate, this.DefineProp('struct', desc)
		(struct := this.struct).Prototype.DefineProp('offset', struct.GetOwnPropDesc('offset'))
		desc := this.GetOwnPropDesc('array'), desc.call := this.array.Call, this.DefineProp('array', desc)
		this.array.DefineProp('Call', { call: this.struct.Call })
		this.array.DefineProp('defval', struct.GetOwnPropDesc('defval'))
		this.array.DefineProp('from_ptr', { call: struct.from_ptr })
		desc := this.GetOwnPropDesc('ptr'), desc.call := this.ptr.Call, this.DefineProp('ptr', desc)
		this.ptr.DefineProp('Call', { call: struct.from_ptr.Bind(, , 1 << 32) })
		desc := this.GetOwnPropDesc('str'), desc.call := this.str.Call, this.DefineProp('str', desc)
		this.str.DefineProp('Call', { call: get_str })
		for k in ['struct', 'array', 'ptr']
			this.%k%.Prototype.DefineProp('__root', { get: (this) => this })

		; add types 
		(tps := this.types).Set('LPSTR', ctypes.str('cp0'), 'LPWSTR', ctypes.str())
		wintypes := {
			char: ['INT8', 'signed char'],
			int: ['BOOL', 'HFILE', 'HRESULT', 'INT32', 'LONG', 'LONG32', 'signed', 'signed int'],
			int64: ['LONG64', 'LONGLONG', '__int64', 'signed __int64'],
			ptr: ['LPARAM', 'LRESULT', 'HWND', 'HANDLE', 'SSIZE_T', 'INT_PTR', 'void*'],
			short: ['INT16', 'signed short'],
			uchar: ['BYTE', 'BOOLEAN', 'UINT8', 'unsigned char'],
			uint: ['UINT32', 'ULONG', 'ULONG32', 'COLORREF', 'DWORD', 'DWORD32', 'unsigned', 'unsigned int'],
			uint64: ['DWORD64', 'DWORDLONG', 'ULONG64', 'ULONGLONG', 'unsigned __int64'],
			uptr: ['WPARAM', 'SIZE_T', 'UINT_PTR'],
			ushort: ['ATOM', 'LANGID', 'UINT16', 'WORD', 'WCHAR', 'wchar_t', 'unsigned short'],
		}, tps := ctypes.types
		for k, arr in wintypes.OwnProps()
			for tp in arr
				tps[tp] := k

		static get_str(this, ptr) => ptr ? StrGet(ptr, this.encoding) : 0
		static generate(this, definition, name := '') {
			definition := RegExReplace(definition, 'm)//.*')
			definition := RegExReplace(definition, '(?<=\w)[ \t\r]+(?!\w)|(?<![\w \t])[ \t\r]+')
			definition := RegExReplace(definition, '([\]>\w])(?=\*+\w)', '$1 ')
			definition := RegExReplace(StrReplace(definition, ';', ';`n'), '[{}]', '`n$0`n')
			definition := RegExReplace(Trim(definition, '`n'), '\n+', '`n')
			definition := RegExReplace(definition, '\n?([,:])\n?', '$1')
			arr := StrSplit(definition, '`n'), arr.Default := '', stack := [top := first := []]
			b := 0, i := 1, l := arr.Length++, pack := '', names := [], name && names.Push(name)
			if RegExMatch(arr.Get(1, ''), '^#pragma\s+pack\(\s*(\d+)\s*\)', &m)
				pack := Integer(m[1]), i++
			while i <= l {
				if RegExMatch(line := arr[i++], '^(typedef\s)?(struct|union)(\s([\w.]+)(:([\w.]+))?)?$', &m) {
					stack.Push(top := []), top.name := joinname(m[4]) || _ := unset, m[2] = 'union' && top.union := true, m[6] && top.extends := m[5]
					if arr[i++] !== '{'
						throw Error('invalid struct')
					if !b++ && name && !first.Length
						top.name := name
					continue
				} else if line == '{' {
					stack.Push(top := []), b++
					continue
				} else if line == '}' {
					if --b < 0
						throw Error('invalid struct', , line)
					tt := stack.Pop(), pack && tt.pack := pack
					tt := create_struct(tt), top := stack[stack.Length]
					if RegExMatch(c := arr[i], '^((\**\w+(\[\d+\])?(,|(?=;?$)))+);?$', &m) {
						for c in StrSplit(m[1], ',')
							top.Push([tt, c])
						i++
					} else top.Push([tt, '']), c == ';' && i++
				} else if RegExMatch(line, '^((struct|union)\s)?(((un)?signed\s)?(\w|::|\.|<[^>]+>)+)(\s((\**\w+(\[\d+\])?(,|(?=;?$)))+))?;?$', &m) {
					if !m[8]
						m[4] ? top.Push(StrSplit(m[3], [' ', '`t'])) : top.Push([m[3], ''])
					else for c in StrSplit(m[8], ',')
						top.Push([m[3], c])
				} else throw Error('invalid struct', , line)
			}
			if b
				throw Error('invalid struct')
			if pack
				top.pack := pack
			if top.Length == 1 && top[1][2] == '' && HasBase(top[1][1], ctypes.struct)
				return top[1][1]
			return create_struct(top, name)
			static create_struct(fields, name := '') {
				struct := ctypes.struct, extends := '', union := unset, pack := unset
				for k in ['union', 'name', 'pack', 'extends']
					if fields.HasOwnProp(k)
						%k% := fields.%k%
				if IsObject(ctypes.types.Get(name, 0))
					throw ValueError('struct ' name ' already exists')
				if extends {
					info := ctypes.__get_typeinfo(extends)
					if !HasBase(struct := info.wrapper, ctypes.struct)
						throw Error('invalid base')
				}
				obj := { base: struct, is_union: union?, pack: pack?, Prototype: { __Class: name } }
				NumPut('uint', 1, 'ptr', ObjPtrAddRef(struct.Prototype), ObjPtr(obj.Prototype), A_PtrSize + 4)
				ObjRelease(ObjPtr(Object.Prototype)), obj.fields := fields
				return obj
			}
			joinname(name, s := '') {
				for n in names
					s .= n '.'
				return s name
			}
		}
	}

	static __Delete() {
		; Release the type cache when ahk exits,
		; avoid some types that have circular references that cannot be released.
		; But in ahk_l, this is not called.
		(Array, Enumerator, MethodError, PropertyError)
		for tp in t := this.types.Get('', [])
			try tp.__dispose()
		for n, tp in this.types
			try this.types[n] := 0, tp.__dispose()
		t.Length := 0, this.types := Map()
	}

	static __Item[name] => this.types.Get(name, 0)

	static __get_prop_desc(offset, type := 0, wrapper := 0, ele_size := 0) {
		static get_buf_ptr := Buffer.Prototype.GetOwnPropDesc('Ptr').Get
		static getters := Map(), setters := Map(), _ := getters.CaseSense := setters.CaseSense := false
		static __ := ctypes.types[0] := { __dispose: (*) => (getters.Clear(), setters.Clear(), getters := setters := 0) }
		return ele_size ? get_array_desc(type, wrapper, ele_size) : get_desc(offset, type, wrapper)

		static get_array_desc(type, wrapper, ele_size) {
			if !wrapper
				getter := getters.Get(key := type ',,' ele_size, 0) || getters[key] := array_get_num,
					setter := setters.Get(key, 0) || setters[key] := array_put_num
			else if type
				getter := getters.Get(key := type ',' ObjPtr(wrapper) ',' ele_size, 0) || getters[key] := array_wrap_num,
					setter := HasMethod(wrapper, 'assign', 2) ?
						(setters.Get(key := ObjPtr(wrapper) ',' ele_size, 0) || setters[key] := array_wrapper_assign) :
						(setters.Get(key := type ',,' ele_size, 0) || setters[key] := array_put_num)
			else
				getter := getters.Get(key := ObjPtr(wrapper) ',' ele_size, 0) || getters[key] := array_wrap_ptr,
					setter := setters.Get(key, 0) || setters[key] := array_wrapper_assign
			return { get: getter, set: setter }
			array_wrap_num(this, index) => _ := wrapper(NumGet(this, ele_size * index, type))
			array_wrap_ptr(this, index) => wrapper.from_ptr(get_buf_ptr(this) + ele_size * index,, this)
			array_get_num(this, index) => NumGet(this, ele_size * index, type)
			array_put_num(this, value, index) => NumPut(type, value, this, ele_size * index)
			array_wrapper_assign(this, value?, index := 0) {
				IsObject(value := wrapper.assign(ptr := get_buf_ptr(this) + ele_size * index, value?, this))
					&& (this := this.__root).%'__cache#' (ptr - this.ptr())% := value
			}
		}
		static get_desc(offset, type, wrapper) {
			if !wrapper
				getter := getters.Get(key := offset ',' type, 0) || getters[key] := NumGet.Bind(, offset, type),
					setter := setters.Get(key, 0) || setters[key] := put_num
			else if type
				getter := getters.Get(key := offset ',' type ',' ObjPtr(wrapper), 0) || getters[key] := wrap_num,
					setter := HasMethod(wrapper, 'assign', 2) ?
						(setters.Get(key := offset ',,' ObjPtr(wrapper), 0) || setters[key] := wrapper_assign) :
						(setters.Get(key := offset ',' type, 0) || setters[key] := put_num)
			else
				getter := getters.Get(key := offset ',,' ObjPtr(wrapper), 0) || getters[key] := wrap_ptr,
					setter := setters.Get(key, 0) || setters[key] := wrapper_assign
			return { get: getter, set: setter }
			wrap_num(this) => _ := wrapper(NumGet(this, offset, type))
			wrap_ptr(this) => wrapper.from_ptr(get_buf_ptr(this) + offset, , this)
			put_num(this, value) => NumPut(type, value, this, offset)
			wrapper_assign(this, value?) {
				IsObject(value := wrapper.assign(ptr := get_buf_ptr(this) + offset, value?, this))
					&& (this := this.__root).%'__cache#' (ptr - this.ptr())% := value
			}
		}
	}

	static __get_typeinfo(tp) {
		static basic_types := { char: 1, uchar: 1, short: 2, ushort: 2, int: 4, uint: 4, float: 4, double: 8, int64: 8, uint64: 8, ptr: A_PtrSize, uptr: A_PtrSize }
		while tp is String {
			if basic_types.HasOwnProp(tp == 'bool' ? tp := 'char' : tp) {
				size := basic_types.%tp%
				return { align: 0, size: size, pack: size, type: tp, name: tp, wrapper: 0 }
			}
			tp := ctypes.types.Get(tp, 0) ||
				((tp := RegExReplace(tp, '\*$', , &n)) && n ? ctypes.ptr(tp) :
				RegExMatch(tp, '^(.+)\[(\d+)\]$', &tp) && ctypes.array(tp[1], Integer(tp[2])))
		}
		if HasBase(tp, ctypes.struct) || HasBase(tp, ctypes.array)
			|| HasProp(tp, 'type') && basic_types.HasOwnProp(type := tp.type) {
			if IsSet(type)
				align := 0, pack := size := basic_types.%type%, !tp.HasProp('name') && tp.name := type
			else {
				size := tp.size, type := 0
				if HasBase(tp, ctypes.struct)
					align := tp.align, pack := tp.__max_align
				else align := 0, pack := tp.align
			}
			return { align: align, size: size, pack: pack, type: type, name: tp.name, wrapper: tp }
		}
		throw TypeError('unknown type')
	}
}
