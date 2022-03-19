module Resolvers.Person.Id exposing (resolver)

import GraphQL.Response exposing (Response)
import Resolvers.Query.Person exposing (Person)


resolver : Person -> () -> Response Int
resolver person args =
    GraphQL.Response.ok person.id