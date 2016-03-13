import Html exposing (..)
import Html.Attributes exposing (..)
import Color exposing (..)
import Graphics.Collage exposing (..)
import Graphics.Element exposing (..)
import Window
import Mouse
import Time exposing (..)
import List
import Random

view : (Int, Int) -> App -> Element
view (width, height) app =
  collage width height
  <| List.map viewEntity app.entities

viewEntity : Entity -> Form
viewEntity entity =
  case entity of
    Cursor object ->
      move (object.pos.x, object.pos.y) kitty
    Turtle object ->
      move (object.pos.x, object.pos.y) doggy

kitty : Form
kitty =
  traced (solid blue) square

doggy : Form
doggy =
  traced (solid red) square

square : Path
square =
  path [ (10, 10), (10, -10), (-10, -10), (-10, 10), (10, 10) ]

-------------- Update methods

update : Input -> App -> App
update input app =
  let
    entities = sourceTurtles input app.entities
      |> collisionDetect
      |> updateEntities input
  in
    { app |
      entities = entities
    }

sourceTurtles : Input -> List Entity -> List Entity
sourceTurtles input entities =
  if List.length entities < 20 then
    createTurtle input :: entities
  else
    entities

collisionDetect : List Entity -> List Entity
collisionDetect entities =
  List.filter (\e -> (getPos e).y > -400.0) entities

updateEntities : Input -> List Entity -> List Entity
updateEntities input entities =
  List.map (updateEntity input) entities

updateEntity : Input -> Entity -> Entity
updateEntity input entity =
  case entity of
    Cursor object ->
      Cursor { object |
        pos = { x = fst input.mouse, y = snd input.mouse }
      }
    Turtle object ->
      Turtle { object |
        pos = { x = object.pos.x, y = object.pos.y - 5 }
      }

-------------- Model methods

type alias App =
  { entities: List Entity
  }

initApp : App
initApp = {
    entities = [
      Cursor { pos = { x = 0.0, y = 400.0 } }
    , Turtle { pos = { x = 0.0, y = 400.0 } }
    ]
  }

type Entity =
  Cursor Object
  | Turtle Object

type alias Object =
  {
    pos : Vec2
  }

type alias Vec2 =
  { x : Float, y : Float }

createTurtle : Input -> Entity
createTurtle input =
  Turtle { pos = {
      x = fst <| Random.generate (Random.float 200 -200) (Random.initialSeed <| floor <| Time.inMilliseconds input.delta)
    , y = 200.0
    }
  }

getPos : Entity -> Vec2
getPos entity =
  case entity of
    Cursor object ->
      object.pos
    Turtle object ->
      object.pos


-------------- Input methods

type alias Input =
  { mouse : (Float, Float)
  , delta: Time }

delta : Signal Time
delta = Signal.map inSeconds (fps 25)

screenToWorld : (Int, Int) -> (Int, Int) -> (Float, Float)
screenToWorld (width, height) (x, y) =
  ((toFloat x) - (toFloat width) / 2,
  -(toFloat y) + (toFloat height) / 2)

input : Signal Input
input =
  Signal.sampleOn delta <|
    Signal.map2 Input
      (Signal.map2 screenToWorld Window.dimensions Mouse.position)
      delta

------------- Main functions

appState : Signal App
appState =
  Signal.foldp update initApp input

main : Signal Element
main =
  Signal.map2 view Window.dimensions appState
