module SomeTests exposing (getAllPossibleIncidentsAboutCwcmds)
import Engine

import Dict exposing (Dict)
import Types as EngineTypes


getListIncidents : Engine.Model -> List (String , List String)
getListIncidents engineModel =
    -- returns list of tuples . first elem of tuple is ruleId and second is a list of incidents associated with that rule
    let

        getListIncidents : List EngineTypes.ChangeWorldCommand -> Engine.Model -> List String
        getListIncidents  lcwcmds enginemodel  =
            Engine.changeWorld lcwcmds enginemodel
             |> Tuple.second

    in
        (Engine.getStoryRules engineModel )
        |> Dict.map  (\id v -> v.changes )
        |> Dict.map (\id lcwcms ->  getListIncidents lcwcms engineModel )
        |> Dict.toList


getaListStringOfPossibleIncidents : List (String , List String) -> List (String , List String) ->  List String
getaListStringOfPossibleIncidents lstartincidents ltups =
    let
        getAString elem =
            Tuple.second elem
            |> String.join "  \n , "
            |> (\x -> if x /= "" then ( "ruleId : " ++ Tuple.first elem ++ " ,   " ++ x ) else "" )

    in
       ltups
        |> List.append lstartincidents
        |> List.map getAString
        |> List.filter (\x -> x /= "" )


getAllPossibleIncidentsAboutCwcmds : Engine.Model -> List (String , List String) -> List String
getAllPossibleIncidentsAboutCwcmds engineModel lstartincidents =
    let
        headerInfo = ["Incidents on tests regarding all possible ChangeWorldCommands :"]
    in
        getListIncidents engineModel
         |> getaListStringOfPossibleIncidents lstartincidents
         |> (\x -> if List.length x > 0 then  (List.append headerInfo x) else [] )
