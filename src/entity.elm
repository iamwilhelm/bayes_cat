module Entity exposing (..)

import Window
import Collage exposing (..)
import Color

import Component.Spatial
import Component.Corporeal
import Component.Label

import Vec exposing (..)
import Input
import Debug


type alias ID = Int

type alias Model = {
    id : ID
  , components : List Component
  }

type Component =
    Spatial Component.Spatial.Model
  | Corporeal Component.Corporeal.Model
  | Label Component.Label.Model
  | Viewable ComponentView

type alias ComponentView = {
    func : Model -> Form
  }

type alias ComponentReduce = {
    func : Model -> Model
  }

-- component

spatial : Vec -> Vec -> Vec -> Component
spatial pos vel acc =
  Spatial <| Component.Spatial.init pos vel acc

corporeal : Vec -> Color.Color -> Component
corporeal dim color =
  Corporeal <| Component.Corporeal.init dim color

label : String -> Color.Color -> Component
label title color =
  Label <| Component.Label.Model title color

viewable : (Model -> Form) -> Component
viewable func =
  Viewable { func = func }

-- accessors

getSpatial : Model -> Maybe Component.Spatial.Model
getSpatial model =
  List.filterMap (\component ->
    case component of
      Spatial spaceModel ->
        Just spaceModel
      _ ->
        Nothing
  ) model.components
  |> List.head

getCorporeal : Model -> Maybe Component.Corporeal.Model
getCorporeal model =
  List.filterMap (\component ->
    case component of
      Corporeal corpModel ->
        Just corpModel
      _ ->
        Nothing
  ) model.components
  |> List.head

getViewable : Model -> Maybe ComponentView
getViewable model =
  List.filterMap (\component ->
    case component of
      Viewable exec ->
        Just exec
      _ ->
        Nothing
  ) model.components
  |> List.head

filterMapSpatial : (Component.Spatial.Model -> Component.Spatial.Model) -> Model -> Model
filterMapSpatial func entity =
  { entity |
    components = List.map (\component ->
        case component of
          Spatial space ->
            Spatial (func space)
          _ ->
            component
      ) entity.components
  }

-- system calls

view : Model -> Maybe Form
view entity =
  let
    maybeViewable = getViewable entity
  in
    case maybeViewable of
      Just viewable ->
        Just <| viewable.func entity
      Nothing ->
        Nothing

boundFloor : Window.Size -> Model -> Model
boundFloor size model =
  filterMapSpatial (\space ->
    let
      (w', h') = (size.width, size.height)
      (w, h) = (toFloat w', toFloat h')
    in
      if Vec.y space.pos < -(h / 2) then
        Component.Spatial.vel (Vec.neg space.vel) space
      else
        space
  ) model

gravity : Float -> Model -> Model
gravity dt entity =
  filterMapSpatial (\space ->
    Component.Spatial.acc ((0, -98060) .* (dt / 1000)) space
  ) entity

newtonian : Float -> Model -> Model
newtonian dt entity =
  filterMapSpatial (\space ->
    let
      space2 = Component.Spatial.vel (space.vel |+ space.acc .* (dt / 1000)) space
    in
      Component.Spatial.pos (space2.pos |+ space2.vel .* (dt / 1000)) space2
  ) entity


--control : Input.Model -> Entity a -> Entity b
--control input entity =
--  map (\model ->
--      { model |
--        space =
--      }
--    ) entity
--
--  { entity |
--    space = entity.control input entity.space
--  }
