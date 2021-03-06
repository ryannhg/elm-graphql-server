module Table.Users.Select exposing
    ( Decoder, new
    , id, username, avatarUrl, posts
    )

{-|

@docs Decoder, new
@docs id, username, avatarUrl, posts

-}

import Database.Select
import Json.Decode
import Table.Users.Column


type alias Decoder value =
    Database.Select.Decoder Table.Users.Column.Column value


new : value -> Decoder value
new value =
    Database.Select.new
        Table.Users.Column.toColumnName
        value


id : Decoder (Int -> value) -> Decoder value
id decoder =
    Database.Select.with Table.Users.Column.id
        Json.Decode.int
        decoder


username : Decoder (String -> value) -> Decoder value
username decoder =
    Database.Select.with Table.Users.Column.username
        Json.Decode.string
        decoder


avatarUrl : Decoder (Maybe String -> value) -> Decoder value
avatarUrl decoder =
    Database.Select.with Table.Users.Column.avatarUrl
        (Json.Decode.maybe Json.Decode.string)
        decoder


posts : Decoder (List post -> value) -> Decoder value
posts decoder =
    Database.Select.return [] decoder
