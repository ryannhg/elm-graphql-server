module GraphQL.Batch exposing (oneToMany)

import Database.Query
import Dict exposing (Dict)
import GraphQL.Info exposing (Info)
import GraphQL.Response exposing (Response)
import List.Extra



-- ONE TO MANY RELATIONSHIPS


{-| Useful when defining a field resolver for one-to-many relationships,
like fetching all posts for a given user:

    type User {
        posts: [Post!]!
    }

This helper function assumes all relationships are modeled consistently, where there are two
SQL queries needed to fetch the one-to-many relationship:

  - One to query the "join table" for all edges, given a list of "key ids"
  - One to query the "values table" for value data, based on the edges that came back from the previous query.

To be concrete, if we were getting all posts for a user, here's what each of these abstract variables
would correspond to:

  - Key ID = User ID (an int)
  - Value ID = Post ID (an int)
  - Edge = `UserAuthoredPost`

Because the `edge` is generic, this function also needs to know how to get data from the edge. For this example,
that would mean:

    type alias UserAuthoredEdge =
        { id : Int
        , userId : Int
        , postId : Int
        }

  - fromEdgeToKeyId = `.userId`
  - fromEdgeToValueId = `.postId`

Finally, we need the `fromValueToValueId` function to know how to get the `id` for a "value". Because our example
is returning `Schema.Post` items, we would need something like this:

  - fromValueToValueId = `\(Schema.Post post) -> post.id`

-}
oneToMany :
    { id : KeyId
    , info : Info
    , fetchEdges : List KeyId -> Database.Query.Query a (List edge)
    , fetchValues : List edge -> Database.Query.Query b (List value)
    , fromEdgeToKeyId : edge -> KeyId
    , fromEdgeToValueId : edge -> ValueId
    , fromValueToValueId : value -> ValueId
    }
    -> Response (List value)
oneToMany options =
    GraphQL.Response.fromBatchQueryForList
        { id = options.id
        , info = options.info
        , toBatchResponse = toBatchResponse options
        }



-- INTERNALS


type alias KeyId =
    Int


type alias ValueId =
    Int


type alias Options edge value a b =
    { id : KeyId
    , info : Info
    , fetchEdges : List KeyId -> Database.Query.Query a (List edge)
    , fetchValues : List edge -> Database.Query.Query b (List value)
    , fromEdgeToKeyId : edge -> KeyId
    , fromEdgeToValueId : edge -> ValueId
    , fromValueToValueId : value -> ValueId
    }


toBatchResponse : Options edge value a b -> List KeyId -> Response (Dict KeyId (List value))
toBatchResponse options userIds =
    options.fetchEdges userIds
        |> GraphQL.Response.fromDatabaseQuery
        |> GraphQL.Response.andThen (toOneToManyValueDict options)


toOneToManyValueDict : Options edge value a b -> List edge -> Response (Dict KeyId (List value))
toOneToManyValueDict options edges =
    let
        groupByKeyId : List value -> Dict KeyId (List value)
        groupByKeyId values =
            let
                valueIdDict : Dict KeyId (List ValueId)
                valueIdDict =
                    edges
                        |> List.Extra.gatherEqualsBy options.fromEdgeToKeyId
                        |> List.map
                            (\( first, rest ) ->
                                ( options.fromEdgeToKeyId first
                                , List.map options.fromEdgeToValueId (first :: rest)
                                )
                            )
                        |> Dict.fromList

                updateDict : KeyId -> Dict KeyId (List value) -> Dict KeyId (List value)
                updateDict keyId dict =
                    let
                        valueIds : List ValueId
                        valueIds =
                            Dict.get keyId valueIdDict
                                |> Maybe.withDefault []

                        valuesMatchingThisKey : List value
                        valuesMatchingThisKey =
                            List.filter
                                (\item ->
                                    List.member (options.fromValueToValueId item) valueIds
                                )
                                values
                    in
                    Dict.insert keyId
                        valuesMatchingThisKey
                        dict
            in
            List.foldl
                updateDict
                Dict.empty
                (Dict.keys valueIdDict)
    in
    options.fetchValues edges
        |> GraphQL.Response.fromDatabaseQuery
        |> GraphQL.Response.map groupByKeyId
