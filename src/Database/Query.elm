module Database.Query exposing (Query, findAll, findOne, toDecoder, toSql)

import Database.Select
import Database.Where
import Json.Decode


type Query column value
    = Find
        { tableName : String
        , where_ : Maybe (Database.Where.Clause column)
        , select : Database.Select.Decoder column value
        , limit : Maybe Int
        }


findOne :
    { tableName : String
    , where_ : Maybe (Database.Where.Clause column)
    , select : Database.Select.Decoder column value
    }
    -> Query column (Maybe value)
findOne options =
    Find
        { tableName = options.tableName
        , where_ = options.where_
        , select = Database.Select.mapDecoder (Json.Decode.index 0 << Json.Decode.maybe) options.select
        , limit = Just 1
        }


findAll :
    { tableName : String
    , select : Database.Select.Decoder column value
    , where_ : Maybe (Database.Where.Clause column)
    , limit : Maybe Int
    }
    -> Query column (List value)
findAll options =
    Find
        { tableName = options.tableName
        , where_ = options.where_
        , select = Database.Select.mapDecoder Json.Decode.list options.select
        , limit = options.limit
        }


toSql : Query column value -> String
toSql query =
    case query of
        Find options ->
            let
                template : String
                template =
                    case ( options.where_, options.limit ) of
                        ( Just whereClause, Just limit ) ->
                            "SELECT {{columns}} FROM {{tableName}} WHERE {{whereClause}} LIMIT {{limit}}"
                                |> String.replace "{{whereClause}}" (Database.Where.toSql whereClause)
                                |> String.replace "{{limit}}" (String.fromInt limit)

                        ( Nothing, Just limit ) ->
                            "SELECT {{columns}} FROM {{tableName}} LIMIT {{limit}}"
                                |> String.replace "{{limit}}" (String.fromInt limit)

                        ( Just whereClause, Nothing ) ->
                            "SELECT {{columns}} FROM {{tableName}} WHERE {{whereClause}}"
                                |> String.replace "{{whereClause}}" (Database.Where.toSql whereClause)

                        ( Nothing, Nothing ) ->
                            "SELECT {{columns}} FROM {{tableName}}"
            in
            template
                |> String.replace "{{tableName}}" options.tableName
                |> String.replace "{{columns}}" (Database.Select.toSql options.select)


toDecoder : Query column value -> Json.Decode.Decoder value
toDecoder query =
    case query of
        Find options ->
            Database.Select.toJsonDecoder options.select
