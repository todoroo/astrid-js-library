# **Astrid.com JS API**
#
# In order to use this API, you will need an
# [Astrid Api Key](http://astrid.com/api_keys).

root = exports ? this

class root.Astrid

  # Construct a new instance of the Astrid API
  constructor: (@server, @apikey, @secret) ->
    @api = 7
    @user = null

  # Initialize Astrid object with a previously saved token
  setToken: (@token) ->

  # Gets current Astrid token
  getToken: -> @token

  # Gets current Astrid user
  getUser: -> @user

  # Check if user is signed in
  isSignedIn: ->
    @token?

  #### API Functions

  # Sign in with email and password. On success, will call the
  # success function with user object.
  signInAs: (email, password, success, error) ->
    self = @
    params =
      email: email,
      provider: "password",
      secret: password
    @sendRequest "user_signin", params, (response) ->
      if response.status == "success"
        self.token = response.token
        self.user = response
        success response if success
      else if error
        error response.message

  # Gets all user lists. On success, will call the callback function with an
  # array of lists.
  getLists: (success, error) ->
    params = {}
    @sendRequest "tag_list", params, (response) ->
      if response.status == "success"
        success response.list if success
      else if error
        error response.message

  # Create a task. On success, will call the callback function with task
  # data.
  createTask: (task, success, error) ->
    task.send_link = true
    params = task
    @sendRequest "task_save", params, (response) ->
      if response.status == "success"
        success response if success
      else if error
        error response.message

  # Add a comment.
  addComment: (comment, success, error) ->
    params = comment
    @sendRequest "comment_add", params, (response) ->
      if response.status == "success"
        success response if success
      else if error
        error response.message

  #### Request and Response Functions

  constructRequest: (method, params) ->
    params.app_id ||= @apikey
    params.token ||= @token
    params.time ||= new Date().getTime() / 1000
    keys = (key for key of params).sort()
    signature = for key in keys
      if params[key] instanceof Array
        key + "[]" + params[key].join(key + "[]")
      else
        key + params[key]
    signature = method + signature.join("") + @secret
    params.sig = Astrid.md5 signature
    for key, value of params
      if value instanceof Array
        params[key] = (encodeURIComponent(item) for item in value)
      else
        params[key] = encodeURIComponent(value)
    params

  xhr: ->
    if (typeof XMLHttpRequest != "undefined")
      new XMLHttpRequest()
    else
      try
        return new ActiveXObject("Msxml2.XMLHTTP.6.0")
      try
        return new ActiveXObject("Msxml2.XMLHTTP.3.0")
      try
        return new ActiveXObject("Microsoft.XMLHTTP")
      throw new Error("This browser does not support XMLHttpRequest.");

  sendRequest: (method, params, callback) ->
    url = @server + "/api/" + @api + "/" + method
    request = new @xhr()
    request.onreadystatechange = ->
      if request.readyState == 4
        if request.responseText == ""
          callback { status: "failure", message: "Empty response received from server." }
        else
          json = Astrid.json_parse request.responseText
          callback json
    request.open "POST", url, true
    request.setRequestHeader "Content-type", "application/x-www-form-urlencoded"
    paramString = []
    requestParams = @constructRequest method, params
    for key, value of requestParams
      if value instanceof Array
        paramString.push(key + "[]=" + item) for item in value
      else
        paramString.push(key + "=" + value)
    request.send paramString.join("&")

# **JSON Implementation**
# From [JSON.org](http://json.org)
root.Astrid.json_parse = (->
  "use strict"
  at = undefined
  ch = undefined
  escapee =
    "\"": "\""
    "\\": "\\"
    "/": "/"
    b: "\b"
    f: "\f"
    n: "\n"
    r: "\r"
    t: "\t"

  text = undefined
  error = (m) ->
    throw
      name: "SyntaxError"
      message: m
      at: at
      text: text

  next = (c) ->
    error "Expected '" + c + "' instead of '" + ch + "'"  if c and c isnt ch
    ch = text.charAt(at)
    at += 1
    ch

  num = ->
    number = undefined
    string = ""
    if ch is "-"
      string = "-"
      next "-"
    while ch >= "0" and ch <= "9"
      string += ch
      next()
    if ch is "."
      string += "."
      string += ch  while next() and ch >= "0" and ch <= "9"
    if ch is "e" or ch is "E"
      string += ch
      next()
      if ch is "-" or ch is "+"
        string += ch
        next()
      while ch >= "0" and ch <= "9"
        string += ch
        next()
    number = +string
    unless isFinite(number)
      error "Bad number"
    else
      number

  str = ->
    hex = undefined
    i = undefined
    string = ""
    uffff = undefined
    if ch is "\""
      while next()
        if ch is "\""
          next()
          return string
        else if ch is "\\"
          next()
          if ch is "u"
            uffff = 0
            i = 0
            while i < 4
              hex = parseInt(next(), 16)
              break  unless isFinite(hex)
              uffff = uffff * 16 + hex
              i += 1
            string += String.fromCharCode(uffff)
          else if typeof escapee[ch] is "string"
            string += escapee[ch]
          else
            break
        else
          string += ch
    error "Bad string"

  white = ->
    next()  while ch and ch <= " "

  word = ->
    switch ch
      when "t"
        next "t"
        next "r"
        next "u"
        next "e"
        return true
      when "f"
        next "f"
        next "a"
        next "l"
        next "s"
        next "e"
        return false
      when "n"
        next "n"
        next "u"
        next "l"
        next "l"
        return null
    error "Unexpected '" + ch + "'"

  value = undefined
  arr = ->
    array = []
    if ch is "["
      next "["
      white()
      if ch is "]"
        next "]"
        return array
      while ch
        array.push value()
        white()
        if ch is "]"
          next "]"
          return array
        next ","
        white()
    error "Bad array"

  obj = ->
    key = undefined
    object = {}
    if ch is "{"
      next "{"
      white()
      if ch is "}"
        next "}"
        return object
      while ch
        key = str()
        white()
        next ":"
        error "Duplicate key \"" + key + "\""  if Object.hasOwnProperty.call(object, key)
        object[key] = value()
        white()
        if ch is "}"
          next "}"
          return object
        next ","
        white()
    error "Bad object"

  value = ->
    white()
    switch ch
      when "{"
        obj()
      when "["
        arr()
      when "\""
        str()
      when "-"
        num()
      else
        (if ch >= "0" and ch <= "9" then num() else word())

  (source, reviver) ->
    result = undefined
    text = source
    at = 0
    ch = " "
    result = value()
    white()
    error "Syntax error"  if ch
    result
)()

# **MD5 Implementation**
# From [JavaScript-MD5](https://github.com/blueimp/JavaScript-MD5)
(($) ->
  safe_add = (x, y) ->
    lsw = (x & 0xFFFF) + (y & 0xFFFF)
    msw = (x >> 16) + (y >> 16) + (lsw >> 16)
    (msw << 16) | (lsw & 0xFFFF)
  bit_rol = (num, cnt) ->
    (num << cnt) | (num >>> (32 - cnt))
  md5_cmn = (q, a, b, x, s, t) ->
    safe_add bit_rol(safe_add(safe_add(a, q), safe_add(x, t)), s), b
  md5_ff = (a, b, c, d, x, s, t) ->
    md5_cmn (b & c) | ((~b) & d), a, b, x, s, t
  md5_gg = (a, b, c, d, x, s, t) ->
    md5_cmn (b & d) | (c & (~d)), a, b, x, s, t
  md5_hh = (a, b, c, d, x, s, t) ->
    md5_cmn b ^ c ^ d, a, b, x, s, t
  md5_ii = (a, b, c, d, x, s, t) ->
    md5_cmn c ^ (b | (~d)), a, b, x, s, t
  binl_md5 = (x, len) ->
    x[len >> 5] |= 0x80 << ((len) % 32)
    x[(((len + 64) >>> 9) << 4) + 14] = len
    i = undefined
    olda = undefined
    oldb = undefined
    oldc = undefined
    oldd = undefined
    a = 1732584193
    b = -271733879
    c = -1732584194
    d = 271733878
    i = 0
    while i < x.length
      olda = a
      oldb = b
      oldc = c
      oldd = d
      a = md5_ff(a, b, c, d, x[i], 7, -680876936)
      d = md5_ff(d, a, b, c, x[i + 1], 12, -389564586)
      c = md5_ff(c, d, a, b, x[i + 2], 17, 606105819)
      b = md5_ff(b, c, d, a, x[i + 3], 22, -1044525330)
      a = md5_ff(a, b, c, d, x[i + 4], 7, -176418897)
      d = md5_ff(d, a, b, c, x[i + 5], 12, 1200080426)
      c = md5_ff(c, d, a, b, x[i + 6], 17, -1473231341)
      b = md5_ff(b, c, d, a, x[i + 7], 22, -45705983)
      a = md5_ff(a, b, c, d, x[i + 8], 7, 1770035416)
      d = md5_ff(d, a, b, c, x[i + 9], 12, -1958414417)
      c = md5_ff(c, d, a, b, x[i + 10], 17, -42063)
      b = md5_ff(b, c, d, a, x[i + 11], 22, -1990404162)
      a = md5_ff(a, b, c, d, x[i + 12], 7, 1804603682)
      d = md5_ff(d, a, b, c, x[i + 13], 12, -40341101)
      c = md5_ff(c, d, a, b, x[i + 14], 17, -1502002290)
      b = md5_ff(b, c, d, a, x[i + 15], 22, 1236535329)
      a = md5_gg(a, b, c, d, x[i + 1], 5, -165796510)
      d = md5_gg(d, a, b, c, x[i + 6], 9, -1069501632)
      c = md5_gg(c, d, a, b, x[i + 11], 14, 643717713)
      b = md5_gg(b, c, d, a, x[i], 20, -373897302)
      a = md5_gg(a, b, c, d, x[i + 5], 5, -701558691)
      d = md5_gg(d, a, b, c, x[i + 10], 9, 38016083)
      c = md5_gg(c, d, a, b, x[i + 15], 14, -660478335)
      b = md5_gg(b, c, d, a, x[i + 4], 20, -405537848)
      a = md5_gg(a, b, c, d, x[i + 9], 5, 568446438)
      d = md5_gg(d, a, b, c, x[i + 14], 9, -1019803690)
      c = md5_gg(c, d, a, b, x[i + 3], 14, -187363961)
      b = md5_gg(b, c, d, a, x[i + 8], 20, 1163531501)
      a = md5_gg(a, b, c, d, x[i + 13], 5, -1444681467)
      d = md5_gg(d, a, b, c, x[i + 2], 9, -51403784)
      c = md5_gg(c, d, a, b, x[i + 7], 14, 1735328473)
      b = md5_gg(b, c, d, a, x[i + 12], 20, -1926607734)
      a = md5_hh(a, b, c, d, x[i + 5], 4, -378558)
      d = md5_hh(d, a, b, c, x[i + 8], 11, -2022574463)
      c = md5_hh(c, d, a, b, x[i + 11], 16, 1839030562)
      b = md5_hh(b, c, d, a, x[i + 14], 23, -35309556)
      a = md5_hh(a, b, c, d, x[i + 1], 4, -1530992060)
      d = md5_hh(d, a, b, c, x[i + 4], 11, 1272893353)
      c = md5_hh(c, d, a, b, x[i + 7], 16, -155497632)
      b = md5_hh(b, c, d, a, x[i + 10], 23, -1094730640)
      a = md5_hh(a, b, c, d, x[i + 13], 4, 681279174)
      d = md5_hh(d, a, b, c, x[i], 11, -358537222)
      c = md5_hh(c, d, a, b, x[i + 3], 16, -722521979)
      b = md5_hh(b, c, d, a, x[i + 6], 23, 76029189)
      a = md5_hh(a, b, c, d, x[i + 9], 4, -640364487)
      d = md5_hh(d, a, b, c, x[i + 12], 11, -421815835)
      c = md5_hh(c, d, a, b, x[i + 15], 16, 530742520)
      b = md5_hh(b, c, d, a, x[i + 2], 23, -995338651)
      a = md5_ii(a, b, c, d, x[i], 6, -198630844)
      d = md5_ii(d, a, b, c, x[i + 7], 10, 1126891415)
      c = md5_ii(c, d, a, b, x[i + 14], 15, -1416354905)
      b = md5_ii(b, c, d, a, x[i + 5], 21, -57434055)
      a = md5_ii(a, b, c, d, x[i + 12], 6, 1700485571)
      d = md5_ii(d, a, b, c, x[i + 3], 10, -1894986606)
      c = md5_ii(c, d, a, b, x[i + 10], 15, -1051523)
      b = md5_ii(b, c, d, a, x[i + 1], 21, -2054922799)
      a = md5_ii(a, b, c, d, x[i + 8], 6, 1873313359)
      d = md5_ii(d, a, b, c, x[i + 15], 10, -30611744)
      c = md5_ii(c, d, a, b, x[i + 6], 15, -1560198380)
      b = md5_ii(b, c, d, a, x[i + 13], 21, 1309151649)
      a = md5_ii(a, b, c, d, x[i + 4], 6, -145523070)
      d = md5_ii(d, a, b, c, x[i + 11], 10, -1120210379)
      c = md5_ii(c, d, a, b, x[i + 2], 15, 718787259)
      b = md5_ii(b, c, d, a, x[i + 9], 21, -343485551)
      a = safe_add(a, olda)
      b = safe_add(b, oldb)
      c = safe_add(c, oldc)
      d = safe_add(d, oldd)
      i += 16
    [ a, b, c, d ]
  binl2rstr = (input) ->
    i = undefined
    output = ""
    i = 0
    while i < input.length * 32
      output += String.fromCharCode((input[i >> 5] >>> (i % 32)) & 0xFF)
      i += 8
    output
  rstr2binl = (input) ->
    i = undefined
    output = []
    output[(input.length >> 2) - 1] = `undefined`
    i = 0
    while i < output.length
      output[i] = 0
      i += 1
    i = 0
    while i < input.length * 8
      output[i >> 5] |= (input.charCodeAt(i / 8) & 0xFF) << (i % 32)
      i += 8
    output
  rstr_md5 = (s) ->
    binl2rstr binl_md5(rstr2binl(s), s.length * 8)
  rstr_hmac_md5 = (key, data) ->
    i = undefined
    bkey = rstr2binl(key)
    ipad = []
    opad = []
    hash = undefined
    ipad[15] = opad[15] = `undefined`
    bkey = binl_md5(bkey, key.length * 8)  if bkey.length > 16
    i = 0
    while i < 16
      ipad[i] = bkey[i] ^ 0x36363636
      opad[i] = bkey[i] ^ 0x5C5C5C5C
      i += 1
    hash = binl_md5(ipad.concat(rstr2binl(data)), 512 + data.length * 8)
    binl2rstr binl_md5(opad.concat(hash), 512 + 128)
  rstr2hex = (input) ->
    hex_tab = "0123456789abcdef"
    output = ""
    x = undefined
    i = undefined
    i = 0
    while i < input.length
      x = input.charCodeAt(i)
      output += hex_tab.charAt((x >>> 4) & 0x0F) + hex_tab.charAt(x & 0x0F)
      i += 1
    output
  str2rstr_utf8 = (input) ->
    unescape encodeURIComponent(input)
  raw_md5 = (s) ->
    rstr_md5 str2rstr_utf8(s)
  hex_md5 = (s) ->
    rstr2hex raw_md5(s)
  raw_hmac_md5 = (k, d) ->
    rstr_hmac_md5 str2rstr_utf8(k), str2rstr_utf8(d)
  hex_hmac_md5 = (k, d) ->
    rstr2hex raw_hmac_md5(k, d)
  md5 = (string, key, raw) ->
    unless key
      unless raw
        return hex_md5(string)
      else
        return raw_md5(string)
    unless raw
      hex_hmac_md5 key, string
    else
      raw_hmac_md5 key, string

  root.Astrid.md5 = md5
) this
