# Elm Game Narrative Starter
 
Elm game/narrative Engine and story starter
adds several extensions to the original Elm Narrative Engine by Jeff Schomay  :
[elm-interactive-story-starter](https://github.com/jschomay/elm-interactive-story-starter)
that were implemented by Nuno Torres


- The ability to pose questions to the player , and the ability for the player to answer those questions
Answers can be checked using just this Elm project or  making  requests to backend APIs

- The ability to add attributes to Interactables , like for instance counters that can be used
to track several different stuff , like for instance the number of times the player enters a location or interacts with another character ...

- the ability to get geoLocation information  , like for instance gps coordinates , and to associate
gps Zones ( circles centered on a given gps coords point with a given radius ) to Locations
and require ( if so desired , its not mandatory ) that the player be located in a given gps Zone
before being allowed to enter a game/narrative location

- support for Several Languages : besides allowing the narrative to reach a greater audience ,
There's almost always several versions/narratives/points of view
around one Single Truth , right  ;)  ...

- several tests to prevent  creating Rules that try to create interactions with non-existant interactables ( characters , items , locations )

- the ability to save/load the interaction history list to Local Storage



# Interactive Story Starter

just like the original Elm Narrative Engine , this project can be (re)used to start your own project.
You just have to rewrite the configuration files  Narrative.elm , Rules.elm and Manifest.elm ( and maybe NarrativeEnglish.elm , etc if you want support for more than one language )


# The examples
Three examples game/narratives ( ourStory , ourStory2 and ourStory3 ) were created
to exemplify how you can use this project to create your own game/narrative


-  __ourStory__ : presents 10 stages each with a question about it , and on each stage you have to answer the question correctly in order to move to the next stage

-  __ourStory2__ : presents 10 stages each with a question about it except for stage 6 ( just as an example ) that doesn't have a question.
Also , as an example , a correct answer is not required in stage 7 in order to proceed to stage 8  ( but a correct answer is still required in order to finish the game )
Some of the questions were converted to a multioption answer type

-  __ourStory3__ : presents 10 stages , where each of the stages might have more than one question or options to choose from ...



Enjoy playing the  guided tour/questionnaire ( proof of concept ) example at
[Guided Tour through Vila Sassetti - Sintra](https://sintraubuntuer.github.io/pages/guided-tour-through-vila-sassetti-sintra.html)
and enjoy creating your interactive story!
