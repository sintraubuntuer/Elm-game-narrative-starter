module OurStory.Manifest exposing (items, locations, characters)

import Components exposing (..)
import OurStory.Rules as Rules
import OurStory.Narrative as Narrative
import Dict exposing (Dict)
import GpsUtils


{- Here is where you define your manifest -- all of the items, characters, and locations in your story. You can add what ever components you wish to each entity.  Note that the first argument to `entity` is the id for that entity, which is the id you must refer to in your rules.
   In the current theme, the description in the display info component is only used as a fallback narrative if a rule does not match with a more specific narrative when interacting with that story object.
-}


initialItems : List Entity
initialItems =
    [ entity "gameStateItem"
    , entity "gps"
        |> addDisplayInfo "GPSr" "Magical Instrument that helps you navigate"
        |> addLgDisplayInfo "pt" "GPSr" "Instrumento mágico que te ajuda a navegar no terreno."
        |> addNeedsGpsInfo True
    , entity "creditsInfo"
        |> addDisplayInfo "credits" "credits Info"
        |> addLgDisplayInfo "pt" "credits" "credits Info"
    , entity "finalPaper"
        |> addDisplayInfo "old paper" "old paper with some info written on it"
        |> addLgDisplayInfo "pt" "papiro" "papiro com alguma informação escrita"
    ]


getListOfItems : List Entity -> Int -> List Entity
getListOfItems initItems nrQuestions =
    let
        createEntity : Int -> Entity
        createEntity nr =
            entity (Rules.getQuestionId nr)
                |> addDisplayInfo (Narrative.getQuestionName nr "en") (Narrative.getQuestionBodyAsString nr "en")
                |> addLgDisplayInfo "pt" (Narrative.getQuestionName nr "pt") (Narrative.getQuestionBodyAsString nr "pt")

        moreItems : List Entity
        moreItems =
            Rules.getListOfStageQuestionNrs
                |> List.map createEntity
    in
        List.append initItems moreItems


items : List Entity
items =
    getListOfItems initialItems Rules.numberOfDesiredStages


characters : List Entity
characters =
    [ entity "playerOne"
        |> addDisplayInfo "investigator" "You ..."
        |> addLgDisplayInfo "pt" "investigador" "Tu ..."
    ]


initialLocations : List Entity
initialLocations =
    [ entity "onceUponAtime"
        |> addDisplayInfo "Once Upon a Time" "Once Upon a Time"
        |> addLgDisplayInfo "pt" "Era Uma Vez ..." "Era Uma Vez ..."
        |> addConnectingLocations [ ( West, "stage1" ) ]
    ]


getStageCoordInfo : Int -> Maybe ( Float, Float, Maybe Float )
getStageCoordInfo stageNr =
    let
        dictCoordInfo : Dict Int ( Float, Float, Maybe Float )
        dictCoordInfo =
            Dict.fromList
                [ ( 1, ( 38.7952, -9.391733, Nothing ) )
                , ( 2, ( 38.795033, -9.391517, Nothing ) )
                , ( 3, ( 38.79475, -9.3914, Nothing ) )
                , ( 4, ( 38.7943, -9.391567, Nothing ) )
                , ( 5, ( 38.79395, -9.391267, Nothing ) )
                , ( 6, ( 38.793717, -9.391167, Nothing ) )
                , ( 7, ( 38.793733, -9.39095, Nothing ) )
                , ( 8, ( 38.793367, -9.391167, Nothing ) )
                , ( 9, ( 38.792367, -9.391267, Nothing ) )
                , ( 10, ( 38.7922, -9.3913, Nothing ) )
                ]
    in
        dictCoordInfo
            |> Dict.get stageNr


getListOfLocations : List Entity -> Int -> List Entity
getListOfLocations initLocations nrLocations =
    let
        getDirection : Int -> Int -> Components.Direction
        getDirection s1 s2 =
            case ( getStageCoordInfo s1, getStageCoordInfo s2 ) of
                ( Just ( lat1, lon1, mbrad1 ), Just ( lat2, lon2, mbrad2 ) ) ->
                    GpsUtils.calculateBearing ( lat1, lon1 ) ( lat2, lon2 )
                        |> toFloat
                        |> Components.bearingToDirection

                ( _, _ ) ->
                    if s2 >= s1 then
                        West
                    else
                        East

        getConnectingLocations stageNr =
            if stageNr == 1 then
                [ ( getDirection 1 2, "stage2" ) ]
            else if stageNr == nrLocations then
                [ ( getDirection nrLocations (nrLocations - 1), (Rules.getStageId (nrLocations - 1)) ) ]
            else
                [ ( getDirection stageNr (stageNr + 1), Rules.getStageId (stageNr + 1) )
                , ( getDirection stageNr (stageNr - 1), Rules.getStageId (stageNr - 1) )
                ]

        mbAddCoordInfo stageNr entity =
            case (getStageCoordInfo stageNr) of
                Nothing ->
                    entity

                Just ( lat, lon, mbRadius ) ->
                    entity
                        |> addNeedsToBeInGpsZone True lat lon mbRadius

        createEntity nr =
            entity (Rules.getStageId nr)
                |> addDisplayInfo (Narrative.getStageName nr "en") (Narrative.interactingWithStageN nr "en" "defaultStageDescription" |> String.join " , ")
                |> addLgDisplayInfo "pt" (Narrative.getStageName nr "pt") (Narrative.interactingWithStageN nr "pt" "defaultStageDescription" |> String.join " , ")
                |> addConnectingLocations (getConnectingLocations nr)
                |> mbAddCoordInfo nr

        moreLocations =
            List.range 1 nrLocations
                |> List.map createEntity
    in
        List.append initLocations moreLocations


locations : List Entity
locations =
    getListOfLocations initialLocations Rules.numberOfDesiredStages
