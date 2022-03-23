module Table.Posts.Select exposing
    ( Decoder, new
    , id, imageUrls, caption
    )

{-|

@docs Decoder, new
@docs id, imageUrls, caption

-}

import Database.Select
import Database.Utils
import Json.Decode
import Table.Posts.Column


type alias Decoder value =
    Database.Select.Decoder Table.Posts.Column.Column value


new : value -> Decoder value
new value =
    Database.Select.new
        Table.Posts.Column.toString
        value


id : Decoder (Int -> value) -> Decoder value
id decoder =
    Database.Select.with Table.Posts.Column.id
        Json.Decode.int
        decoder


imageUrls : Decoder (List String -> value) -> Decoder value
imageUrls decoder =
    Database.Select.with Table.Posts.Column.imageUrls
        (Database.Utils.decodeJsonTextColumn (Json.Decode.list Json.Decode.string))
        decoder


caption : Decoder (String -> value) -> Decoder value
caption decoder =
    Database.Select.with Table.Posts.Column.caption
        Json.Decode.string
        decoder
