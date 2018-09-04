module Components exposing (..)

import Engine
import Dict exposing (..)
import List.Zipper as Zipper exposing (Zipper)


{-| An entity is simply an id associated with some potential components and their data.
Each object in your story is an entity - this includes items, locations, and characters, but also rules too.
-}
type alias Entity =
    ( String, Components )


type alias Components =
    Dict String Component


{-| These are all of the available components.
You can add your own components and the data that goes with them as needed. Be sure to implement adders and getters below as well.
See the functions below for more info on specific components.
-}
type Component
    = DisplayInformation (Dict String { name : String, description : String })
    | ClassName String
    | ConnectingLocations Exits
    | Narrative (Zipper String)
    | LanguageNarratives (Dict String (Zipper String))
    | AudioContent (Dict String AudioFileInfo)
    | RuleData Engine.Rule
    | NeedsGpsCoords Bool
    | NeedsToBeInGpsZone Bool Float Float (Maybe Float) -- bool decimallatitude decimallongitude (maybe radius)


type alias Exits =
    List ( Direction, String )


type Direction
    = North
    | NorthEast
    | NorthWest
    | South
    | SouthEast
    | SouthWest
    | East
    | West


type alias AudioFileInfo =
    { displayName : String, fileName : String, mbAbsoluteUrl : Maybe String }


{-| A helper to quickly make an entity which can be easily piped into the component adders below.
The id that you set is the id that you must use to reference this entity in your rules.
-}
entity : String -> Entity
entity id =
    ( id, Dict.empty )


addComponent : String -> Component -> Entity -> Entity
addComponent componentId component ( id, components ) =
    ( id, Dict.insert componentId component components )



-- Helpers to add the above components to an entity, which can be easily piped together
{- adds Display info in english "en" language -}


addDisplayInfo : String -> String -> Entity -> Entity
addDisplayInfo name description ( id, components ) =
    --addComponent "displayInfo" <| DisplayInformation { name = name, description = description }
    addLgDisplayInfo "en" name description ( id, components )


addLgDisplayInfo : String -> String -> String -> Entity -> Entity
addLgDisplayInfo lgId name description ( id, components ) =
    let
        newDict =
            case Dict.get "displayInfo" components of
                Just (DisplayInformation dict) ->
                    Dict.insert lgId { name = name, description = description } dict

                _ ->
                    Dict.insert lgId { name = name, description = description } Dict.empty
    in
        addComponent "displayInfo" (DisplayInformation newDict) ( id, components )



{- updates the name of an entity for all languages -}


updateAllLgsDisplayName : String -> Entity -> Entity
updateAllLgsDisplayName newNameStr ( id, components ) =
    let
        newDict =
            case Dict.get "displayInfo" components of
                Just (DisplayInformation dict) ->
                    Dict.map (\key val -> { val | name = newNameStr }) dict

                _ ->
                    Dict.empty
    in
        addComponent "displayInfo" (DisplayInformation newDict) ( id, components )


addAllLanguagesAudio : Dict String AudioFileInfo -> Entity -> Entity
addAllLanguagesAudio audioDict ( id, components ) =
    addComponent "audioContent" (AudioContent audioDict) ( id, components )


addLgAudioContent : String -> String -> String -> Maybe String -> Entity -> Entity
addLgAudioContent lgId audioName audioFileName mbAbsUrl ( id, components ) =
    let
        newDict =
            case Dict.get "audioContent" components of
                Just (AudioContent dict) ->
                    Dict.insert lgId (AudioFileInfo audioName audioFileName mbAbsUrl) dict

                _ ->
                    Dict.insert lgId (AudioFileInfo audioName audioFileName mbAbsUrl) Dict.empty
    in
        addComponent "audioContent" (AudioContent newDict) ( id, components )


getMbSingleLgAudioContent : String -> Entity -> Maybe AudioFileInfo
getMbSingleLgAudioContent lgId ( id, components ) =
    let
        mbAudioComponent =
            Dict.get "audioContent" components

        audioDict =
            case mbAudioComponent of
                Just (AudioContent dict) ->
                    dict

                _ ->
                    Dict.empty
    in
        Dict.get lgId audioDict


getLanguagesAudioDict : Entity -> Dict String AudioFileInfo
getLanguagesAudioDict ( id, components ) =
    case Dict.get "audioContent" components of
        Just (AudioContent audioDict) ->
            audioDict

        _ ->
            Dict.empty


{-| Add classes to your entities to do some custom styling, such as to change a background color or image based on the location, or to show an avatar in the story line when a character is talking. You can write the styles in the `Theme/styles/story.css` file.
Note that the string that you specify will appear in different places in the theme, often in a BEM format, so you may need to inspect the DOM to find what you wish to style.
-}
addClassName : String -> Entity -> Entity
addClassName className =
    addComponent "className" <| ClassName className


{-| This allows you to specify which locations are adjacent to the current location, and in what direction. If you use this component, the view will show adjacent locations regardless of what locations have been added via the `addLocation` change world command from the Engine.
You can change the Directions as needed.
-}
addConnectingLocations : List ( Direction, String ) -> Entity -> Entity
addConnectingLocations exits =
    addComponent "connectedLocations" <| ConnectingLocations exits


{-| The Narrative component is intended only for rule entities.
The narrative that you add to a rule will be shown when that rule matches. If you give a list of strings, each time the rule matches, it will show the next narrative in the list, which is nice for adding variety and texture to your story.
-}
addNarrative : List String -> Entity -> Entity
addNarrative narrative =
    addComponent "narrative" <| Narrative <| Zipper.withDefault "" <| Zipper.fromList narrative


zipTheStringList : List String -> Zipper String
zipTheStringList narrative =
    Zipper.withDefault "" <| Zipper.fromList narrative


makeZipNarrativesDict : Dict String (List String) -> Dict String (Zipper String)
makeZipNarrativesDict narrativeDict =
    Dict.map (\comparable lstrs -> zipTheStringList lstrs) narrativeDict


addLanguageNarratives : Dict String (List String) -> Entity -> Entity
addLanguageNarratives narrativeDict =
    addComponent "languageNarratives" <| LanguageNarratives <| makeZipNarrativesDict narrativeDict


{-| The RuleData component is intended only for rule entities, and is the only component that is used directly by the Engine, while all other components are used by the client code.
-}
addRuleData : Engine.Rule -> Entity -> Entity
addRuleData ruleData =
    addComponent "ruleData" <| RuleData ruleData


{-| determines wether this entity or interactable needs actual gps coordinates when interacted with ...
might be useful to create a gps item that gives gps coords info to the user
-}
addNeedsGpsInfo : Bool -> Entity -> Entity
addNeedsGpsInfo bval =
    addComponent "needsGpsCoords" <| NeedsGpsCoords bval


addNeedsToBeInGpsZone : Bool -> Float -> Float -> Maybe Float -> Entity -> Entity
addNeedsToBeInGpsZone bval dlat dlon mbRadius =
    addComponent "needsToBeInGpsZone" <| (NeedsToBeInGpsZone bval dlat dlon mbRadius)



-- Helpers to get the component data out of an entity
-- Will return a sensible default if the entity does not have the requested component


getDisplayInfo : Entity -> { name : String, description : String }
getDisplayInfo ( id, components ) =
    getSingleLgDisplayInfo "en" ( id, components )



{- get entity displayInfo on a given language identified by lgId : languageId string -}


getSingleLgDisplayInfo : String -> Entity -> { name : String, description : String }
getSingleLgDisplayInfo lgId ( id, components ) =
    let
        theDict =
            getLgsDisplayInfo [ lgId ] ( id, components )
    in
        Dict.get lgId theDict
            |> Maybe.withDefault { name = "No Info", description = "No Info" }



-- cant really happen because of the way getLgsDisplayInfo function is defined
{- gets (returns ) the dictionary ( languageId -> {name , description} ) of display infos
   Returns a dict with  the keys passed in as args as mandatory
   and using a prior dict passed in as argument ( only the keys not already present in the prior are filled in)
   if the key is not present in the display infos
   uses as default the english display info and if that doesn't  exist uses the entity id
-}


getTheLgsDisplayInfo : List String -> Dict String { name : String, description : String } -> Entity -> Dict String { name : String, description : String }
getTheLgsDisplayInfo ldesiredlanguageIds priorDict ( id, components ) =
    let
        dict1 =
            case Dict.get "displayInfo" components of
                Just (DisplayInformation dict) ->
                    dict

                _ ->
                    Dict.empty

        mergedDict =
            mergeDicts dict1 priorDict

        fillIt : String -> Dict String { name : String, description : String } -> Dict String { name : String, description : String }
        fillIt key dict =
            case (Dict.get key dict) of
                Just val ->
                    dict

                Nothing ->
                    case (Dict.get "en" dict) of
                        Nothing ->
                            Dict.insert key { name = id, description = id } dict

                        Just englishVal ->
                            Dict.insert key englishVal dict
    in
        -- try to fill values for keys not yet in dictionary
        List.foldl (\key dict -> fillIt key dict) mergedDict ldesiredlanguageIds



{- same as the previous  not using any prior dict -}


getLgsDisplayInfo : List String -> Entity -> Dict String { name : String, description : String }
getLgsDisplayInfo ldesiredlanguageIds ( id, components ) =
    getTheLgsDisplayInfo ldesiredlanguageIds Dict.empty ( id, components )


getDictLgNames : List String -> Entity -> Dict String String
getDictLgNames ldesiredlanguageIds ( id, components ) =
    let
        dict =
            getLgsDisplayInfo ldesiredlanguageIds ( id, components )
    in
        Dict.map (\key val -> val.name) dict


getDictLgNamesAndCoords : List String -> Entity -> Dict String ( String, Float, Float )
getDictLgNamesAndCoords ldesiredlanguageIds ( id, components ) =
    case (Dict.get "needsToBeInGpsZone" components) of
        Just (NeedsToBeInGpsZone bval dlat dlon mbRadius) ->
            let
                dict =
                    getLgsDisplayInfo ldesiredlanguageIds ( id, components )
            in
                Dict.map (\key val -> ( val.name, dlat, dlon )) dict

        _ ->
            Dict.empty


getEntityCoords : Entity -> Maybe ( Float, Float )
getEntityCoords ( id, components ) =
    case (Dict.get "needsToBeInGpsZone" components) of
        Just (NeedsToBeInGpsZone bval dlat dlon mbRadius) ->
            Just ( dlat, dlon )

        _ ->
            Nothing


getDictLgDescriptions : List String -> Entity -> Dict String String
getDictLgDescriptions ldesiredlanguageIds ( id, components ) =
    let
        dict =
            getLgsDisplayInfo ldesiredlanguageIds ( id, components )
    in
        Dict.map (\key val -> val.description) dict



{-
   getWrittenContent : Entity -> Maybe String
   getWrittenContent ( id, components ) =
       case Dict.get "writtenContent" components of
           Just ( WrittenContent mbtext ) ->
               mbtext
           _ ->
               Nothing


   getDescriptionInfoAndWrittenContent : Entity -> String
   getDescriptionInfoAndWrittenContent ( id, components ) =
       (getDisplayInfo ( id, components )).description ++ ( Maybe.withDefault "" (getWrittenContent (id , components)) )
-}


getNeedsGpsCoords : Entity -> Bool
getNeedsGpsCoords ( id, components ) =
    case (Dict.get "needsGpsCoords" components) of
        Just (NeedsGpsCoords True) ->
            True

        _ ->
            False


getNeedsToBeInGpsZone : Entity -> Maybe { needsToBeIn : Bool, lat : Float, lon : Float, mbRadius : Maybe Float }
getNeedsToBeInGpsZone ( id, components ) =
    case (Dict.get "needsToBeInGpsZone" components) of
        Just (NeedsToBeInGpsZone bval dlat dlon mbRadius) ->
            Just { needsToBeIn = bval, lat = dlat, lon = dlon, mbRadius = mbRadius }

        _ ->
            Nothing


getClassName : Entity -> String
getClassName ( id, components ) =
    case Dict.get "className" components of
        Just (ClassName className) ->
            className

        _ ->
            ""


getExits : Entity -> Exits
getExits ( id, components ) =
    case Dict.get "connectedLocations" components of
        Just (ConnectingLocations exits) ->
            exits

        _ ->
            []


getNarrative : Entity -> Zipper String
getNarrative ( id, components ) =
    case Dict.get "narrative" components of
        Just (Narrative narrative) ->
            narrative

        _ ->
            Zipper.singleton id


getLanguageNarrative : String -> Entity -> Zipper String
getLanguageNarrative languageId ( id, components ) =
    case Dict.get "languageNarratives" components of
        Just (LanguageNarratives narrativesDict) ->
            case (Dict.get languageId narrativesDict) of
                Just narrative ->
                    narrative

                _ ->
                    Zipper.singleton id

        _ ->
            Zipper.singleton id


getLanguagesNarrativeDict : Entity -> Dict String (Zipper String)
getLanguagesNarrativeDict ( id, components ) =
    case Dict.get "languageNarratives" components of
        Just (LanguageNarratives narrativesDict) ->
            narrativesDict

        _ ->
            Dict.empty


getRuleData : Entity -> Engine.Rule
getRuleData ( id, components ) =
    case Dict.get "ruleData" components of
        Just (RuleData rule) ->
            rule

        _ ->
            { interaction = Engine.with ""
            , conditions = []
            , changes = []
            , quasiChanges = []
            , quasiChangeWithBkend = Engine.noQuasiChangeWithBackend
            }


bearingToDirection : Float -> Direction
bearingToDirection angle =
    if (angle >= 22.5 && angle < 67.5) then
        NorthEast
    else if (angle >= 67.5 && angle < 112.5) then
        East
    else if (angle >= 112.5 && angle < 157.5) then
        SouthEast
    else if (angle >= 157.5 && angle < 202.5) then
        South
    else if (angle >= 202.5 && angle < 247.5) then
        SouthWest
    else if (angle >= 247.5 && angle < 292.5) then
        West
    else if (angle >= 292.5 && angle < 337.5) then
        NorthWest
    else
        North


mergeDicts : Dict comparable v -> Dict comparable v -> Dict comparable v
mergeDicts dict1 dict2 =
    let
        ltups =
            Dict.toList dict1

        mergeRule : ( comparable, v ) -> Dict comparable v -> Dict comparable v
        mergeRule tup dict =
            if Dict.get (Tuple.first tup) dict == Nothing then
                Dict.insert (Tuple.first tup) (Tuple.second tup) dict
            else
                dict
    in
        List.foldl (\tup dict -> mergeRule tup dict) dict2 ltups
