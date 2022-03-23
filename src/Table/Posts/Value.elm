module Table.Posts.Value exposing (Value, caption, imageUrls)

import Database.Value
import Json.Encode
import Table.Posts.Column


type alias Value =
    Database.Value.Value Table.Posts.Column.Column


imageUrls : List String -> Value
imageUrls value =
    Database.Value.json Table.Posts.Column.imageUrls (\list -> Json.Encode.list Json.Encode.string list) value


caption : String -> Value
caption value =
    Database.Value.text Table.Posts.Column.caption value
