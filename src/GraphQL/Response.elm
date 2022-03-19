module GraphQL.Response exposing
    ( Response
    , ok, err
    , fromQuery
    , toCmd
    )

{-|

@docs Response
@docs ok, err
@docs fromQuery

@docs toCmd

-}

import Database.Query
import Json.Decode
import Json.Encode
import Task exposing (Task)


type Response value
    = Success value
    | Failure Json.Decode.Value
    | Query
        { sql : String
        , onResponse : Json.Decode.Value -> Response value
        }


ok : value -> Response value
ok value =
    Success value


err : Json.Decode.Value -> Response value
err reason =
    Failure reason


fromQuery : Database.Query.Query column value -> Response value
fromQuery query =
    Query
        { sql = Database.Query.toSql query
        , onResponse =
            \json ->
                case Json.Decode.decodeValue (Database.Query.toDecoder query) json of
                    Ok value ->
                        ok value

                    Err problem ->
                        err (Json.Encode.string (Json.Decode.errorToString problem))
        }


toCmd :
    { onSuccess : value -> Cmd msg
    , onFailure : Json.Decode.Value -> Cmd msg
    , onDatabaseQuery :
        { sql : String
        , onResponse : Json.Decode.Value -> Cmd msg
        }
        -> msg
    }
    -> Response value
    -> Cmd msg
toCmd options response =
    case response of
        Success value ->
            options.onSuccess value

        Failure reason ->
            options.onFailure reason

        Query query ->
            sendMessage
                (options.onDatabaseQuery
                    { sql = query.sql
                    , onResponse = \json -> toCmd options (query.onResponse json)
                    }
                )


sendMessage : msg -> Cmd msg
sendMessage msg =
    Task.succeed msg |> Task.perform identity