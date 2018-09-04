module Audio exposing (..)

import ClientTypes exposing (AudioFileInfo)
import Dict exposing (Dict)


testFunc : String
testFunc =
    "test"



{- just an example of how it could be done

   interactingWithPlayerOneAudioDict : Dict String AudioFileInfo
   interactingWithPlayerOneAudioDict =
       Dict.fromList
           [ ( "pt", AudioFileInfo "player audio" "playersound.mp3" Nothing )
           , ( "en", AudioFileInfo "player_audio" "playersound.mp3" Nothing )
           ]

-}
