extends Node
## All the show content lives here. Add to any list and the game picks it up.
## Twist rows: [name, text, kind, chaos, energy, heart, coherence]
## Constraint rows: [text, difficulty 1 to 3]
## Every stats array is in this order: [chaos, energy, heart, coherence]

const KINDS := ["physical", "narrative", "time", "meta", "audience"]

const KIND_LABELS := {
	"physical": "Physical",
	"narrative": "Narrative",
	"time": "Time",
	"meta": "Meta",
	"audience": "Audience",
}

const SUGGESTION_PROMPTS := {
	"A place": "Where would you never bring a date?",
	"An object": "What is in your junk drawer?",
	"A job": "What is a job that sounds made up?",
	"A feeling": "What did you feel at the DMV?",
	"A tradition": "What is a small-town tradition?",
	"A word": "Give us a word that is fun to say.",
	"A chore": "What household chore do you avoid?",
	"A fear": "What is a small, silly fear?",
}

const SUGGESTION_EXAMPLES := {
	"A place": ["a roller rink", "a dentist waiting room", "a golf course at night", "a ferry"],
	"An object": ["a rubber band", "a lone key", "a broken umbrella", "a dead battery"],
	"A job": ["professional line-stander", "pillow tester", "cloud inspector", "goat yoga teacher"],
	"A feeling": ["dread", "boredom", "surprise relief", "misplaced confidence"],
	"A tradition": ["the pie toss", "the lantern walk", "the founders' day parade", "the town sleepover"],
	"A word": ["kerfuffle", "bamboozle", "flapjack", "hullabaloo"],
	"A chore": ["folding fitted sheets", "cleaning the fridge", "taking out recycling", "dusting"],
	"A fear": ["moths", "revolving doors", "automatic faucets", "group chats"],
}

const FORMATS := [
	{
		"id": "harold",
		"name": "Three-Beat Harold",
		"desc": "Three beats of two scenes each. Beat three has to bring back things from beat one.",
		"beats": [2, 2, 2],
		"scene_sec": 140,
		"monologue": false,
		"cast_rule": "fair",
	},
	{
		"id": "montage",
		"name": "Quick Montage",
		"desc": "Eight short scenes in two beats. Fast, light, and lots of fresh starts.",
		"beats": [4, 4],
		"scene_sec": 85,
		"monologue": false,
		"cast_rule": "fair",
	},
	{
		"id": "duel",
		"name": "Two-Hander Duel",
		"desc": "The same two performers carry every scene. Everyone else supports from the wings and tags in on twists.",
		"beats": [2, 2],
		"scene_sec": 150,
		"monologue": false,
		"cast_rule": "fixed_pair",
	},
	{
		"id": "chain",
		"name": "Chain Reaction",
		"desc": "Five scenes with no breaks. The last line of each scene becomes the first line of the next.",
		"beats": [5],
		"scene_sec": 120,
		"monologue": false,
		"cast_rule": "fair",
	},
	{
		"id": "armando",
		"name": "Monologue Show",
		"desc": "Each beat opens with a true story. The scenes that follow are inspired by it.",
		"beats": [3, 3],
		"scene_sec": 125,
		"monologue": true,
		"cast_rule": "fair",
	},
	{
		"id": "sandbox",
		"name": "Open Sandbox",
		"desc": "Two beats of three scenes. Every option stays on the table. Steer as you like.",
		"beats": [3, 3],
		"scene_sec": 150,
		"monologue": false,
		"cast_rule": "fair",
	},
]

const LOCATIONS := [
	"A 24-hour laundromat at 3 a.m.",
	"The back of a moving truck",
	"A school gym after the dance",
	"A tiny kitchen during a family argument",
	"A public library after closing",
	"An airport gate with a canceled flight",
	"A rooftop garden",
	"The last booth in a diner",
	"A community college hallway",
	"A lighthouse with bad Wi-Fi",
	"A farmers market at opening",
	"A hospital waiting room",
	"A bus stop in the rain",
	"A bed and breakfast that might be haunted",
	"A rented cabin with only one bed",
	"Level three of a parking garage",
	"A wedding reception tent",
	"A museum gift shop",
	"A canoe in the middle of a lake",
	"A neighborhood block party",
	"Backstage at a tiny theater",
	"A mountain trailhead at sunrise",
	"An elevator that has stopped",
	"A used bookstore",
	"A desert road with a flat tire",
	"A karaoke bar on a Tuesday",
]

const RELATIONSHIPS := [
	"Old college roommates",
	"Rival food truck owners",
	"A parent and a grown child",
	"Two strangers sharing a ride",
	"A boss and a new hire",
	"Neighbors who share a fence",
	"Siblings who inherited a house",
	"Best friends, and one is moving away",
	"A coach and a retired star player",
	"Newlyweds on day one",
	"Two exes who bump into each other",
	"Coworkers on the night shift",
	"A tour guide and a skeptical tourist",
	"A mentor and a stubborn student",
	"Cousins at a funeral",
	"Roommates dividing the fridge",
	"A customer and a very honest cashier",
	"A detective and a reluctant witness",
	"A grandparent and a teenager",
	"Two rival bakers",
]

const WANTS := [
	"To get an apology",
	"To keep a secret",
	"To leave without being noticed",
	"To win a bet",
	"To say goodbye properly",
	"To borrow something important",
	"To finish a project before dawn",
	"To be believed",
	"To get invited",
	"To return something that was taken",
	"To confess something small",
	"To find a missing item",
	"To stop someone from leaving",
	"To get permission",
	"To prove a point",
	"To throw the perfect surprise",
	"To fix a mistake before anyone sees",
	"To get a straight answer",
	"To be left alone",
	"To get the last one",
]

const OBSTACLES := [
	"The power keeps flickering",
	"Someone is listening",
	"There is only one of the thing they need",
	"A promise from long ago",
	"Someone is lying",
	"Time is running out",
	"Everyone is pretending not to care",
	"A very loud noise nearby",
	"The rules are unclear",
	"One person keeps changing their mind",
	"They disagree about what happened",
	"Someone is extremely sleepy",
	"An awkward third wheel is present",
	"They are all out of money",
	"A misunderstanding keeps growing",
	"The weather turns bad",
	"Someone is secretly recording",
	"A rival shows up",
	"They cannot speak freely",
	"Everything is slightly broken",
]

const OPENERS := [
	"I thought you said you'd be here at noon.",
	"You are not going to believe what I found.",
	"We need to talk about the thing.",
	"Did you bring it?",
	"I can explain, but you won't like it.",
	"Welcome back. You look different.",
	"I've been practicing what to say.",
	"Okay, nobody panic.",
	"Is this seat taken?",
	"That's not what I ordered.",
	"I wasn't going to tell you this yet.",
	"It's smaller than I remembered.",
	"Quick, before they notice.",
	"I owe you an apology.",
	"Please tell me you're joking.",
	"How long have you been standing there?",
	"This is the worst idea we've had.",
	"Say it again, slower.",
	"I think we're lost.",
	"We have exactly one chance.",
]

const EMOTIONS := [
	"nervous excitement",
	"quiet pride",
	"suppressed laughter",
	"simmering resentment",
	"deep relief",
	"tender worry",
	"stubborn optimism",
	"playful rivalry",
	"exhausted kindness",
	"awkward hope",
	"grand confidence",
	"nostalgia",
	"guilty joy",
	"fierce loyalty",
	"gentle suspicion",
	"wide-eyed wonder",
]

const GENRES := [
	"horror",
	"musical",
	"western",
	"soap opera",
	"nature documentary",
	"heist movie",
	"fairy tale",
	"noir detective story",
	"sports broadcast",
	"romantic comedy",
	"space opera",
	"reality TV",
]

const TIME_JUMPS := [
	"Ten years earlier",
	"Ten years later",
	"The next morning",
	"One hour before it all began",
	"A century later",
	"The day before",
]

const CONSTRAINTS := [
	["No questions allowed.", 2],
	["Only speak in questions.", 3],
	["Whisper everything.", 2],
	["Speak only in sentences of five words or fewer.", 2],
	["One performer may only answer in single words.", 2],
	["Everyone keeps one hand on something at all times.", 1],
	["Narrate your own actions in the third person.", 2],
	["Treat every object as precious.", 1],
	["All dialogue must be extremely polite.", 1],
	["Start every line with someone's name.", 1],
	["Every character is terrible at lying.", 1],
	["Speak as if this is the most important meeting of your life.", 1],
	["Stay three steps apart. No touching.", 1],
	["Use a rule of three at least once.", 2],
	["End the scene on a callback.", 2],
	["Nobody may use the word 'the'.", 3],
	["Every line must add a new fact about the world.", 2],
	["Everyone speaks in a slightly different accent.", 3],
]

const TWISTS := [
	["Slow Motion", "Everyone plays in slow motion until someone breaks the spell with a line.", "physical", 6, 2, 0, -2],
	["Underwater", "The whole scene is underwater now. Commit to the physicality.", "physical", 8, 3, 0, -3],
	["Tiny Space", "The room is shrinking. Everyone must stay within arm's reach.", "physical", 5, 4, 2, 0],
	["Mirror Mirror", "Pair up and copy your partner's movements exactly for a minute.", "physical", 6, 3, 2, -2],
	["The Floor Is Lava", "The floor is lava. Keep moving without touching it.", "physical", 9, 6, 0, -4],
	["Silent Movie", "No words for thirty seconds. Tell the story with your bodies.", "physical", 4, 2, 3, 0],
	["Tiptoe Mode", "Everyone starts whispering and tiptoeing. Someone nearby is sleeping.", "physical", 3, 0, 3, 1],
	["Giant Hands", "Everything is oversized. Handle each object as if it were enormous.", "physical", 5, 3, 0, 0],
	["Slow Dance", "Everyone takes a slow dance moment. Let the tenderness land.", "physical", 2, -2, 8, 1],
	["Secret Revealed", "One character reveals a secret that changes how the others see them.", "narrative", 4, 3, 6, 2],
	["Mistaken Identity", "Someone is not who they said they were.", "narrative", 6, 4, 2, -2],
	["The Phone Rings", "A phone rings. The call changes the stakes of the scene.", "narrative", 3, 2, 2, 3],
	["Unexpected Guest", "Someone new arrives. Whoever is closest to the exit plays them.", "narrative", 5, 5, 2, 0],
	["Old Debt", "Someone owes someone else a promise they made years ago.", "narrative", 3, 1, 5, 3],
	["Strange Local Rule", "Reveal one odd rule about this world that everyone has always known.", "narrative", 7, 3, 0, -1],
	["Betrayal", "One character has been working against the others the whole time.", "narrative", 8, 5, -2, 0],
	["Miracle", "Something impossibly good happens. Respond honestly.", "narrative", 3, 4, 7, -1],
	["Bad News", "News arrives that changes what everyone wants.", "narrative", 2, 1, 4, 3],
	["Apology Tour", "A character must sincerely apologize to everyone present.", "narrative", 3, 1, 7, 2],
	["Rewind", "Rewind thirty seconds and replay the moment with one change.", "time", 6, 4, 0, -3],
	["One Year Later", "It is one year later. Show what changed.", "time", 5, 3, 3, 0],
	["Flashback", "Cut to the moment this all began.", "time", 4, 2, 4, 3],
	["The Next Morning", "It is the next morning. Deal with the consequences.", "time", 3, 2, 1, 2],
	["Two-Minute Deadline", "It must be done in two minutes or all is lost.", "time", 6, 8, 0, 1],
	["Warning From Later", "A character announces what will go wrong. No one believes them.", "time", 7, 3, 1, -2],
	["Genre Swap", "Switch genres right now: horror, musical, western, or soap opera.", "meta", 9, 6, 0, -3],
	["Narrator Arrives", "One performer becomes a narrator and describes what the others do.", "meta", 5, 3, 2, 2],
	["Swap Roles", "Swap characters with a partner.", "meta", 6, 5, 0, -2],
	["Sing It", "The next three lines are sung.", "meta", 7, 7, 2, -2],
	["Say It Honestly", "For one minute, characters say exactly what they feel.", "meta", 3, 0, 8, 2],
	["Break the Wall", "One character realizes they are in a show and says so.", "meta", 10, 5, 1, -5],
	["Freeze and Tag", "Freeze. Someone tags out a character and continues with a new angle.", "meta", 4, 6, 0, 0],
	["Quiet Moment", "Everyone drops to half volume. Find the quiet truth.", "meta", 0, -4, 6, 3],
	["Ask the Room", "Ask the audience for one noun and make it matter right away.", "audience", 5, 5, 2, -1],
	["Applause Meter", "Keep the scene going only as long as the audience keeps clapping softly.", "audience", 6, 6, 2, -3],
	["Vote on It", "The audience votes between two possible outcomes.", "audience", 3, 4, 3, 1],
	["Name Drop", "Ask the audience for a first name and put that person in the scene.", "audience", 6, 5, 3, -1],
	["The Heckler", "A character becomes a heckler. The others must win them over.", "audience", 6, 5, 1, -2],
]

const DIRECTIONS := [
	{"id": "new_world", "name": "New World", "text": "Fresh location, fresh people, fresh start."},
	{"id": "same_world", "name": "Same World, New Eyes", "text": "Keep the location. New characters and a new relationship."},
	{"id": "same_people", "name": "Same People, New Place", "text": "Keep the cast. Move them somewhere new."},
	{"id": "time_jump", "name": "Time Jump", "text": "Keep the location and relationship, but change the time."},
	{"id": "minor", "name": "The Minor Character", "text": "Follow a person who was mentioned but never seen."},
	{"id": "callback", "name": "The Callback", "text": "Rebuild the scene around a fact you logged earlier."},
	{"id": "mirror", "name": "The Mirror", "text": "Same setup as the last scene, with the status flipped."},
	{"id": "genre", "name": "Genre Shift", "text": "Same world, but now it is a different genre."},
	{"id": "wildcard", "name": "Wildcard", "text": "Everything is random. Trust the dice."},
]

const BEAT_RULES := [
	"Every scene must include a recurring prop.",
	"No scene may take place indoors.",
	"At least one character in each scene is a returning character.",
	"Every scene must contain a secret.",
	"Each scene ends with a question.",
	"Characters are unusually polite.",
	"Everyone is slightly late to everything.",
	"Every scene has exactly one lie in it.",
	"Someone in every scene is trying to leave.",
	"Each scene must include one sincere compliment.",
]

const WARMUPS := [
	{"name": "Zip Zap Zop", "text": "Stand in a circle. Pass energy with a clap and say Zip, Zap, or Zop in order. Keep the rhythm going."},
	{"name": "One-Word Story", "text": "Tell a story one word at a time around the circle. Keep it moving; do not plan ahead."},
	{"name": "Emotional Greeting", "text": "Greet each other in turn, each time with a different emotion the next person names."},
	{"name": "Pass the Clap", "text": "Send one clap around the circle as fast as possible. Then add a second clap going the other way."},
	{"name": "Alphabet Conversation", "text": "In pairs, hold a conversation where each line begins with the next letter of the alphabet."},
	{"name": "Status Walk", "text": "Walk around the room. Take on a status from one to ten and notice how others react."},
	{"name": "Mirror Pairs", "text": "In pairs, one leads and one mirrors. Switch leaders without saying a word."},
	{"name": "Group Count", "text": "Count to twenty as a group, one person at a time, without planning an order. Restart if two speak at once."},
	{"name": "Yes, And Planning", "text": "In pairs, plan a party. Every sentence must begin with Yes, and."},
	{"name": "What Are You Doing?", "text": "One person mimes an action. Another asks what they are doing and they answer with something different. Swap."},
]

const MONOLOGUE_PROMPTS := [
	"Tell a true story about a time you were sure you were right and you were not.",
	"Tell a true story about a small kindness from a stranger.",
	"Tell a true story about the worst advice you ever followed.",
	"Tell a true story about something you lost and where you found it.",
	"Tell a true story about a family tradition that nobody can explain.",
	"Tell a true story about a time you were very, very early or very, very late.",
	"Tell a true story about a first day of something.",
	"Tell a true story about a meal you still think about.",
	"Tell a true story about getting lost.",
	"Tell a true story about a neighbor.",
	"Tell a true story about a promise you almost kept.",
	"Tell a true story about a place that felt different at night.",
]

const DICE_TIERS := {
	"disaster": {
		"label": "Critical Fumble",
		"color": "ff6b6b",
		"stats": [10, 4, -2, -6],
		"texts": [
			"Something everyone relied on fails completely.",
			"A character's worst fear walks in.",
			"The thing that was supposed to be secret is now public.",
			"The plan has one fatal flaw. Find it out loud.",
		],
	},
	"complication": {
		"label": "Complication",
		"color": "ffb347",
		"stats": [5, 3, 0, -2],
		"texts": [
			"A small problem gets bigger.",
			"Someone misunderstands a key detail.",
			"An important item goes missing.",
			"A new rule makes everything harder.",
			"Someone arrives at the worst possible moment.",
		],
	},
	"nudge": {
		"label": "Nudge",
		"color": "a89fbd",
		"stats": [0, 1, 1, 2],
		"texts": [
			"A useful detail surfaces. Build on it.",
			"A character remembers something helpful.",
			"A small coincidence helps out.",
			"The mood shifts slightly. Follow it.",
		],
	},
	"gift": {
		"label": "A Gift",
		"color": "8be28b",
		"stats": [-2, 3, 5, 3],
		"texts": [
			"An ally appears with exactly what is needed.",
			"A character makes a brave choice. Celebrate it.",
			"Two characters finally understand each other.",
			"A joke lands and everyone relaxes.",
		],
	},
	"miracle": {
		"label": "Critical Success",
		"color": "6ee7d8",
		"stats": [-3, 8, 8, 4],
		"texts": [
			"Everything clicks into place. Play the perfect moment.",
			"The scene reveals what it was about all along.",
			"A hidden connection ties every thread together.",
		],
	},
}

const RATINGS := [
	{"name": "Flop", "text": "We lost the room.", "stats": [0, -10, -5, -5], "value": 0},
	{"name": "Fine", "text": "Solid and steady.", "stats": [0, 0, 0, 0], "value": 1},
	{"name": "Hit", "text": "The room leaned in.", "stats": [0, 8, 6, 2], "value": 2},
	{"name": "Legendary", "text": "People will talk about this.", "stats": [4, 14, 10, 4], "value": 3},
]

const HEADLINES := {
	"chaos": ["A Beautiful Disaster", "Controlled Demolition", "Gloriously Unhinged"],
	"heart": ["A Show With a Pulse", "Tenderness in the Wreckage", "Honest and Warm"],
	"energy": ["Lightning in a Bottle", "Nonstop Momentum", "Fast, Loud, and Fun"],
	"coherence": ["A Story That Actually Landed", "Quietly Masterful", "Tight, Clever, and Connected"],
	"flat": ["A Slow Burn", "Gentle and Under-Cooked", "An Evening of Maybe"],
}

const REVIEW_OPENERS := [
	"Tonight the performers took a theme of %s and ran with it.",
	"With %s hanging over the room, the ensemble found its footing.",
	"Anchored by the suggestion of %s, the cast set out to build a world.",
]

const REVIEW_CLOSERS := [
	"Audiences will leave humming the last scene.",
	"It is the kind of show people retell in the parking lot.",
	"Next time, someone should bring snacks.",
	"A strong night for an ensemble that listened.",
]
