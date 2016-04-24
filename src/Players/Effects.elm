module Players.Effects (..) where

import Effects exposing (Effects)
import Http
import Json.Decode as Decode exposing ((:=))
import Json.Encode as Encode
import Task

import Players.Models exposing (PlayerId, Player)
import Players.Actions exposing (..)


-- Fetch All

fetchAllUrl : String
fetchAllUrl =
  "http://localhost:4000/players"

fetchAll : Effects Action
fetchAll =
  Http.get collectionDecoder fetchAllUrl
    |> Task.toResult
    |> Task.map FetchAllDone
    |> Effects.task

-- Create

createUrl : String
createUrl =
  "http://localhost:4000/players"

create : Player -> Effects Action
create player =
  let
    body =
      memberEncoded player
        |> Encode.encode 0
        |> Http.string

    config =
      { verb = "POST"
      , headers = [ ( "Content-Type", "application/json" ) ]
      , url = createUrl
      , body = body
      }
  in
    -- This can be switched to Post now
    Http.send Http.defaultSettings config
      |> Http.fromJson memberDecoder
      |> Task.toResult
      |> Task.map CreatePlayerDone
      |> Effects.task

-- Delete

deleteUrl : PlayerId -> String
deleteUrl playerId =
  "http://localhost:4000/players/" ++ (toString playerId)

deleteTask : PlayerId -> Task.Task Http.Error ()
deleteTask playerId =
  let
    config =
      { verb = "DELETE"
      , headers = [ ( "Content-Type", "application/json" ) ]
      , url = deleteUrl playerId
      , body = Http.empty
      }
  in
    -- This can be switched to Post now
    Http.send Http.defaultSettings config
      |> Http.fromJson (Decode.succeed ())

delete : PlayerId -> Effects Action
delete playerId =
  deleteTask playerId
    |> Task.toResult
    |> Task.map (DeletePlayerDone playerId)
    |> Effects.task

-- Save

saveUrl : Int -> String
saveUrl playerId =
  "http://localhost:4000/players/" ++ (toString playerId)

saveTask : Player -> Task.Task Http.Error Player
saveTask player =
  let
    body =
      memberEncoded player
        |> Encode.encode 0
        |> Http.string

    config =
      { verb = "PATCH"
      , headers = [ ( "Content-Type", "application/json" ) ]
      , url = saveUrl player.id
      , body = body
      }
  in
    Http.send Http.defaultSettings config
      |> Http.fromJson memberDecoder

save : Player -> Effects Action
save player =
  saveTask player
    |> Task.toResult
    |> Task.map SaveDone
    |> Effects.task


-- Decoders

collectionDecoder : Decode.Decoder (List Player)
collectionDecoder =
  Decode.list memberDecoder

memberDecoder : Decode.Decoder Player
memberDecoder =
  Decode.object3
    Player
    ("id" := Decode.int)
    ("name" := Decode.string)
    ("level" := Decode.int)

memberEncoded : Player -> Encode.Value
memberEncoded player =
  let
    list =
      [ ( "id", Encode.int player.id )
      , ( "name", Encode.string player.name )
      , ( "level", Encode.int player.level )
      ]
  in
    list
      |> Encode.object
