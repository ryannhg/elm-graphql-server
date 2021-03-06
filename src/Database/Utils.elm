module Database.Utils exposing (decodeJsonTextColumn, wrapListValue, wrapStringValue)

import Json.Decode


{-| Wraps raw string values so string literals don't accidentally
become invalid SQL syntax or [bobby drop tables](https://xkcd.com/327/).

SQL strings are wrapped in **single quotes**, and we use `''` to escape single quote characters

Here are some examples:

  - `Ryan` -> `'Ryan'`
  - `Ryan's so cool!` -> `'Ryan''s so cool!'`
  - `Ryan "Cool guy" Haskell` -> `'Ryan "Cool guy" Haskell'`

-}
wrapStringValue : String -> String
wrapStringValue str =
    "'" ++ String.replace "'" "''" str ++ "'"


{-| Formats a list of values to a SQL list, for use in `IN` clauses.

    wrapListValue String.fromInt [ 1, 2, 3 ] == "( 1, 2, 3 )"

    wrapListValue wrapStringValue [ "A", "B", "C" ] == "( 'A', 'B', 'C' )"

-}
wrapListValue : (value -> String) -> List value -> String
wrapListValue toString values =
    case values of
        [] ->
            "()"

        items ->
            "( " ++ (List.map toString values |> String.join ", ") ++ " )"


{-| In our SQL database, we store our JSON as raw TEXT columns.

This helper makes it easy to provide a JSON decoder, and handles
dealing with the string value internally:

decodeJsonTextColumn (Json.Decode.list Json.Decode.int)
-- "[1,2,3]"

-}
decodeJsonTextColumn : Json.Decode.Decoder value -> Json.Decode.Decoder value
decodeJsonTextColumn decoder =
    Json.Decode.string
        |> Json.Decode.andThen
            (\rawJsonString ->
                case Json.Decode.decodeString decoder rawJsonString of
                    Ok value ->
                        Json.Decode.succeed value

                    Err err ->
                        Json.Decode.fail (Json.Decode.errorToString err)
            )
