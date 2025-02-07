import std/json
import std/strformat
import std/strutils
import ../rdb_types
import ../rdb_utils


# ==================== SELECT ====================

proc selectSql*(self: Rdb): Rdb =
  var queryString = ""

  if self.query.hasKey("distinct"):
    queryString.add("SELECT DISTINCT")
  else:
    queryString.add("SELECT")

  if self.query.hasKey("select"):
    for i, item in self.query["select"].getElems():
      if i > 0: queryString.add(",")
      var column = item.getStr()
      quote(column, self.driver)
      queryString.add(&" {column}")
  else:
    queryString.add(" *")

  self.queryString = queryString
  return self


proc fromSql*(self: Rdb): Rdb =
  var table = self.query["table"].getStr()
  quote(table, self.driver)
  self.queryString.add(&" FROM {table}")
  return self


proc selectFirstSql*(self:Rdb): Rdb =
  self.queryString.add(" LIMIT 1")
  return self


proc selectByIdSql*(self:Rdb, key:string): Rdb =
  var key = key
  quote(key, self.driver)
  if self.queryString.contains("WHERE"):
    self.queryString.add(&" AND {key} = ? LIMIT 1")
  else:
    self.queryString.add(&" WHERE {key} = ? LIMIT 1")
  return self


proc joinSql*(self: Rdb): Rdb =
  if self.query.hasKey("join"):
    for row in self.query["join"]:
      var table = row["table"].getStr()
      quote(table, self.driver)
      var column1 = row["column1"].getStr()
      quote(column1, self.driver)
      var symbol = row["symbol"].getStr()
      var column2 = row["column2"].getStr()
      quote(column2, self.driver)

      self.queryString.add(&" INNER JOIN {table} ON {column1} {symbol} {column2}")
  return self


proc leftJoinSql*(self: Rdb): Rdb =
  if self.query.hasKey("left_join"):
    for row in self.query["left_join"]:
      var table = row["table"].getStr()
      quote(table, self.driver)
      var column1 = row["column1"].getStr()
      quote(column1, self.driver)
      var symbol = row["symbol"].getStr()
      var column2 = row["column2"].getStr()
      quote(column2, self.driver)

      self.queryString.add(&" LEFT JOIN {table} ON {column1} {symbol} {column2}")
  return self


proc whereSql*(self: Rdb): Rdb =
  if self.query.hasKey("where"):
    for i, row in self.query["where"].getElems():
      var column = row["column"].getStr()
      quote(column, self.driver)
      var symbol = row["symbol"].getStr()
      var value = row["value"].getStr()

      if i == 0:
        self.queryString.add(&" WHERE {column} {symbol} {value}")
      else:
        self.queryString.add(&" AND {column} {symbol} {value}")
  return self


proc orWhereSql*(self: Rdb): Rdb =
  if self.query.hasKey("or_where"):
    for row in self.query["or_where"]:
      var column = row["column"].getStr()
      quote(column, self.driver)
      var symbol = row["symbol"].getStr()
      var value = row["value"].getStr()

      if self.queryString.contains("WHERE"):
        self.queryString.add(&" OR {column} {symbol} {value}")
      else:
        self.queryString.add(&" WHERE {column} {symbol} {value}")
  return self


proc whereBetweenSql*(self:Rdb): Rdb =
  if self.query.hasKey("where_between"):
    for row in self.query["where_between"]:
      var column = row["column"].getStr()
      quote(column, self.driver)
      var start = row["width"][0].getFloat()
      var stop = row["width"][1].getFloat()

      if self.queryString.contains("WHERE"):
        self.queryString.add(&" AND {column} BETWEEN {start} AND {stop}")
      else:
        self.queryString.add(&" WHERE {column} BETWEEN {start} AND {stop}")
  return self


proc whereBetweenStringSql*(self:Rdb): Rdb =
  if self.query.hasKey("where_between_string"):
    for row in self.query["where_between_string"]:
      var column = row["column"].getStr()
      quote(column, self.driver)
      var start = row["width"][0].getStr
      var stop = row["width"][1].getStr

      if self.queryString.contains("WHERE"):
        self.queryString.add(&" AND {column} BETWEEN '{start}' AND '{stop}'")
      else:
        self.queryString.add(&" WHERE {column} BETWEEN '{start}' AND '{stop}'")
  return self


proc whereNotBetweenSql*(self:Rdb): Rdb =
  if self.query.hasKey("where_not_between"):
    for row in self.query["where_not_between"]:
      var column = row["column"].getStr()
      quote(column, self.driver)
      var start = row["width"][0].getFloat()
      var stop = row["width"][1].getFloat()

      if self.queryString.contains("WHERE"):
        self.queryString.add(&" AND {column} NOT BETWEEN {start} AND {stop}")
      else:
        self.queryString.add(&" WHERE {column} NOT BETWEEN {start} AND {stop}")
  return self


proc whereNotBetweenStringSql*(self:Rdb): Rdb =
  if self.query.hasKey("where_not_between_string"):
    for row in self.query["where_not_between_string"]:
      var column = row["column"].getStr()
      quote(column, self.driver)
      var start = row["width"][0].getStr
      var stop = row["width"][1].getStr

      if self.queryString.contains("WHERE"):
        self.queryString.add(&" AND {column} NOT BETWEEN '{start}' AND '{stop}'")
      else:
        self.queryString.add(&" WHERE {column} NOT BETWEEN '{start}' AND '{stop}'")
  return self


proc whereInSql*(self:Rdb): Rdb =
  if self.query.hasKey("where_in"):
    var widthString = ""
    for row in self.query["where_in"]:
      var column = row["column"].getStr()
      quote(column, self.driver)
      for i, val in row["width"].getElems():
        if i > 0: widthString.add(", ")
        if val.kind == JInt:
          widthString.add($(val.getInt()))
        elif val.kind == JFloat:
          widthString.add($(val.getFloat()))
        elif val.kind == JString:
          widthString.add(&"'{val.getStr()}'")

      if self.queryString.contains("WHERE"):
        self.queryString.add(&" AND {column} IN ({widthString})")
      else:
        self.queryString.add(&" WHERE {column} IN ({widthString})")
  return self


proc whereNotInSql*(self:Rdb): Rdb =
  if self.query.hasKey("where_not_in"):
    var widthString = ""
    for row in self.query["where_not_in"]:
      var column = row["column"].getStr()
      quote(column, self.driver)
      for i, val in row["width"].getElems():
        if i > 0: widthString.add(", ")
        if val.kind == JInt:
          widthString.add($(val.getInt()))
        elif val.kind == JFloat:
          widthString.add($(val.getFloat()))
        elif val.kind == JString:
          widthString.add(&"'{val.getStr()}'")

      if self.queryString.contains("WHERE"):
        self.queryString.add(&" AND {column} NOT IN ({widthString})")
      else:
        self.queryString.add(&" WHERE {column} NOT IN ({widthString})")
  return self


proc whereNullSql*(self:Rdb): Rdb =
  if self.query.hasKey("where_null"):
    for row in self.query["where_null"]:
      var column = row["column"].getStr()
      quote(column, self.driver)
      if self.queryString.contains("WHERE"):
        self.queryString.add(&" AND {column} is null")
      else:
        self.queryString.add(&" WHERE {column} is null")
  return self


proc groupBySql*(self:Rdb): Rdb =
  if self.query.hasKey("group_by"):
    for row in self.query["group_by"]:
      var column = row["column"].getStr()
      quote(column, self.driver)
      if self.queryString.contains("GROUP BY"):
        self.queryString.add(&", {column}")
      else:
        self.queryString.add(&" GROUP BY {column}")
  return self


proc havingSql*(self:Rdb): Rdb =
  if self.query.hasKey("having"):
    for i, row in self.query["having"].getElems():
      var column = row["column"].getStr()
      quote(column, self.driver)
      var symbol = row["symbol"].getStr()
      var value = row["value"].getStr()

      if i == 0:
        self.queryString.add(&" HAVING {column} {symbol} {value}")
      else:
        self.queryString.add(&" AND {column} {symbol} {value}")

  return self


proc orderBySql*(self:Rdb): Rdb =
  if self.query.hasKey("order_by"):
    for row in self.query["order_by"]:
      var column = row["column"].getStr()
      quote(column, self.driver)
      var order = row["order"].getStr()

      if self.queryString.contains("ORDER BY"):
        self.queryString.add(&", {column} {order}")
      else:
        self.queryString.add(&" ORDER BY {column} {order}")
  return self


proc limitSql*(self: Rdb): Rdb =
  if self.query.hasKey("limit"):
    var num = self.query["limit"].getInt()
    self.queryString.add(&" LIMIT {num}")

  return self


proc offsetSql*(self: Rdb): Rdb =
  if self.query.hasKey("offset"):
    var num = self.query["offset"].getInt()
    self.queryString.add(&" OFFSET {num}")

  return self


# ==================== INSERT ====================

proc insertSql*(self: Rdb): Rdb =
  var table = self.query["table"].getStr()
  quote(table, self.driver)
  self.queryString = &"INSERT INTO {table}"
  return self


proc insertValueSql*(self: Rdb, items: JsonNode): Rdb =
  var columns = ""
  var values = ""

  var i = 0
  for key, val in items.pairs:
    if i > 0:
      columns.add(", ")
      values.add(", ")
    i += 1
    # If column name contains Upper letter, column name is covered by double quote
    var key = key
    quote(key, self.driver)
    columns.add(key)

    if val.kind == JInt:
      self.placeHolder.add($(val.getInt()))
    elif val.kind == JFloat:
      self.placeHolder.add($(val.getFloat()))
    elif val.kind == JBool:
      let val =
        if val.getBool():
          1
        else:
          0
      self.placeHolder.add($val)
    elif val.kind == JObject:
      self.placeHolder.add($val)
    elif val.kind == JNull:
      self.placeHolder.add("null")
    else:
      self.placeHolder.add(val.getStr())
    values.add("?")

  self.queryString.add(&" ({columns}) VALUES ({values})")
  return self


proc insertValuesSql*(self: Rdb, rows: openArray[JsonNode]): Rdb =
  var columns = ""

  var i = 0
  for key, value in rows[0]:
    if i > 0: columns.add(", ")
    i += 1
    # If column name contains Upper letter, column name is covered by double quote
    var key = key
    quote(key, self.driver)
    columns.add(key)

  var values = ""
  var valuesCount = 0
  for items in rows:
    var valueCount = 0
    var value = ""
    for key, val in items.pairs:
      if valueCount > 0: value.add(", ")
      valueCount += 1
      if val.kind == JInt:
        self.placeHolder.add($(val.getInt()))
      elif val.kind == JFloat:
        self.placeHolder.add($(val.getFloat()))
      elif val.kind == JBool:
        let val =
          if val.getBool():
            1
          else:
            0
        self.placeHolder.add($val)
      elif val.kind == JObject:
        self.placeHolder.add($val)
      elif val.kind == JNull:
        self.placeHolder.add("null")
      else:
        self.placeHolder.add(val.getStr())
      value.add("?")

    if valuesCount > 0: values.add(", ")
    valuesCount += 1
    values.add(&"({value})")

  self.queryString.add(&" ({columns}) VALUES {values}")
  return self


# ==================== UPDATE ====================

proc updateSql*(self: Rdb): Rdb =
  var queryString = ""
  queryString.add("UPDATE")

  var table = self.query["table"].getStr()
  quote(table, self.driver)
  queryString.add(&" {table} SET ")
  self.queryString = queryString
  return self


proc updateValuesSql*(self: Rdb, items:JsonNode): Rdb =
  var value = ""

  var i = 0
  for key, val in items.pairs:
    if i > 0: value.add(", ")
    i += 1
    var key = key
    quote(key, self.driver)
    value.add(&"{key} = ?")

  self.queryString.add(value)
  return self


# ==================== DELETE ====================

proc deleteSql*(self: Rdb): Rdb =
  self.queryString = "DELETE"
  return self


proc deleteByIdSql*(self: Rdb, id: int, key: string): Rdb =
  var key = key
  quote(key, self.driver)
  self.queryString.add(&" WHERE {key} = ?")
  return self

# ==================== Aggregates ====================

proc selectCountSql*(self: Rdb): Rdb =
  var queryString =
    if self.query.hasKey("select"):
      var column = self.query["select"][0].getStr
      quote(column, self.driver)
      &"{column}"
    else:
      "*"
  self.queryString = &"SELECT count({queryString}) as aggregate"
  return self


proc selectMaxSql*(self:Rdb, column:string): Rdb =
  var column = column
  quote(column, self.driver)
  self.queryString = &"SELECT max({column}) as aggregate"
  return self


proc selectMinSql*(self:Rdb, column:string): Rdb =
  var column = column
  quote(column, self.driver)
  self.queryString = &"SELECT min({column}) as aggregate"
  return self


proc selectAvgSql*(self:Rdb, column:string): Rdb =
  var column = column
  quote(column, self.driver)
  self.queryString = &"SELECT avg({column}) as aggregate"
  return self


proc selectSumSql*(self:Rdb, column:string): Rdb =
  var column = column
  quote(column, self.driver)
  self.queryString = &"SELECT sum({column}) as aggregate"
  return self
