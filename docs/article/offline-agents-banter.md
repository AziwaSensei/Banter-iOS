# The Friend Who Knew Every Score

*Building agents that live on the phone, on iOS and Android*

*Part of the AI in Mobile series. Companion code: [Banter for iOS](https://github.com/AziwaSensei/Banter-iOS) and [Banter for Android](https://github.com/AziwaSensei/OfflineBanterChat).*

---

## How this started

My friend Paul knows sports. Not the way a man who reads the headlines knows sports; the way a man knows his own compound. Mention any team and he tells you who they played last weekend, who scored, who limped off in the second half, and what the manager said afterwards. He looks nothing up.

Sitting with him one evening, I noticed something about myself. Every time he said a name, I reached for my phone to confirm it, and every time the phone made me wait. By the time the score loaded he had moved on to another match. I was always one conversation behind.

Walking home I thought: what I want is a Paul in my pocket. Someone I can ask a plain question and get a plain answer, even where the signal dies. And then the second thought, the one that cost me several weekends: the phones we carry now ship with language models inside them. Why should every question travel to a server and back?

That is how Banter came about. I built it twice, once for iOS and once for Android, and the two came out quite different, which was the most instructive part. This article is what I learned: what offline really buys you and costs you, how Apple and Google have each approached it, the one error that kept chasing me on iOS, and a way of thinking about agents in an app that I call **Agents as a Service**.

---

## Two apps, one name

**On iOS**, Banter is a sports agent. You pick a league and ask about this week's fixtures, the table, or how your team is doing. Apple's on-device model answers, but it does not guess at scores. It calls tools that read a local database, which is filled from ESPN's public endpoints when there is a network and left alone when there is not. The reply is a short paragraph; the app draws the full table under it.

![iOS: pick a league](https://raw.githubusercontent.com/AziwaSensei/Banter-iOS/main/docs/screenshots/01-league-picker.png)
*iOS: pick a league*
![iOS: the empty chat with suggested questions](https://raw.githubusercontent.com/AziwaSensei/Banter-iOS/main/docs/screenshots/02-empty-chat.png)
*iOS: the empty chat with suggested questions*
![iOS: the Premier League table under the model's reply](https://raw.githubusercontent.com/AziwaSensei/Banter-iOS/main/docs/screenshots/03-standings-table.png)
*iOS: the Premier League table under the model's reply*
![iOS: this week's NFL schedule under the reply](https://raw.githubusercontent.com/AziwaSensei/Banter-iOS/main/docs/screenshots/04-schedule-table.png)
*iOS: this week's NFL schedule under the reply*

**On Android**, Banter became a group chat. Every member is a fictional character with a trade, a way of talking and a secret only they know: Musa the barber, Grace the teacher who corrects everyone's English, Pastor Ben who takes football too seriously. Each is an agent built with JetBrains' Koog framework, running on a Gemma model stored in the phone. You say something; one of them answers; if you go quiet, they carry on among themselves.

![Android: pick a group](https://raw.githubusercontent.com/AziwaSensei/Banter-iOS/main/docs/screenshots/android-01-home.png)
*Android: pick a group*
![Android: the empty chat with opening lines](https://raw.githubusercontent.com/AziwaSensei/Banter-iOS/main/docs/screenshots/android-02-empty-chat.png)
*Android: the empty chat with opening lines*
![Android: Musa, Grace and Pastor Ben, all running on the phone](https://raw.githubusercontent.com/AziwaSensei/Banter-iOS/main/docs/screenshots/android-03-chat.png)
*Android: Musa, Grace and Pastor Ben, all running on the phone*

Why the difference? Because the two platforms hand you different things, and I let each app become what its platform made easy. We will come to that.

---

## What offline buys you, and what it costs

**The advantages are real.** The first token arrives before your thumb leaves the screen. Nothing in the question leaves the device, so privacy is structural rather than promised. A chatty user costs you nothing more than a quiet one. And it works on the bus, in the basement, and in the village where the signal is one bar on a good day.

**So are the costs.** The models are small, around three billion parameters for Apple's and for Gemma 4 E2B. They summarise well and fall apart when asked to reason over long tables. Apple's context window is fixed and small, 4,096 tokens on iOS 26 and 8,192 on the iOS 27 simulator I tested on, and everything counts against it. Device coverage is narrow: Apple Intelligence phones on one side, Google's Gemini Nano list on the other, or a 2.6 GB download if you bring your own model. And generation is the most expensive thing the phone does while your app is open. The Android characters only talk while the screen is visible, because the first version warmed my hand.

**The grey areas are where the thinking happens.**

- *Offline is a spectrum.* The iOS model runs offline; the facts come from ESPN. The app is offline-first with a fifteen-minute cache and stale rows when the network is gone. Say precisely what works offline.
- *You do not control the model.* Apple updates its model with the operating system, and one day your tuned instructions behave differently. Bundle your own and you own the weights, the licence, the download and the updates.
- *Licensing is not a footnote.* Gemma builds are licence-gated. A direct download often fails with a 401 until the user accepts the terms and pastes a token. The Android app offers "import a file you already have" first, because that path works.
- *A small model is a blunt judge.* The iOS guardrail asks the model one yes/no question: is this about sports? One day it refused "Show me the table" as off-topic, a question the app itself was suggesting. A three-billion-parameter classifier needs very clear instructions and the benefit of the doubt.
- *Evaluation is on you.* There is no dashboard. You write the test questions and run them yourself.

---

## What the two platforms give you

Side by side:

**Model.** On iOS: Apple's, shipped with the OS, about 3B parameters. On Android: Gemini Nano via AICore, or your own (Gemma through LiteRT-LM).

**API.** On iOS: `LanguageModelSession`. On Android: ML Kit GenAI Prompt API (beta) for Gemini Nano; LiteRT-LM for your own model.

**Agent framework.** On iOS: Built in: tools, structured output, a readable transcript. On Android: Not built in. Koog gives you agents; you wire it to the device yourself.

**Tool calling.** On iOS: First class: a `Tool` struct with `@Generable` arguments, the framework runs the loop. On Android: Engine-dependent; the Prompt API does not expose it the same way.

**Context window.** On iOS: Fixed: 4,096 tokens on iOS 26, 8,192 reported on iOS 27. On Android: Prompt API about 4,000 input tokens; your own model, bounded by memory.

**Who can run it.** On iOS: Apple Intelligence devices, iOS 26 and later. On Android: Gemini Nano: a device list; your own model: anything with the RAM.

**On iOS**, Apple gave me an agent in a box. The session holds the transcript; I give it instructions and tools; when the model needs the standings, the framework calls my tool and feeds the result back.

```swift
session = LanguageModelSession(
    tools: [
        SportsScheduleTool(league: league, store: store),
        SportsStandingsTool(league: league, store: store),
        DateTool(),
    ],
    instructions: Self.instructions(for: league)
)
```

A tool is a small struct whose `@Generable` arguments tell the model its shape. The guardrail uses the same trick to get a typed answer instead of parsing "yes" out of prose:

```swift
@Generable
struct Verdict {
    @Guide(description: "True when the message is about sports, or is a greeting or small talk about this chat.")
    let isOnTopic: Bool
}
let verdict = try await session.respond(to: message, generating: Verdict.self).content
```

Notice the `DateTool`. The model has no clock. Without a tool that says what day it is, "tonight" resolves against the wrong year. You learn this by watching it fail.

**On Android**, nobody handed me a box. Google's ML Kit Prompt API on Gemini Nano is a good prompt-and-response API, but it is not an agent framework and it only runs on the phones Google blesses. Koog is a proper agent framework in Kotlin, but out of the box it talks to hosted providers, not to a model on your phone. The request for that is still an open issue on the Koog repository, and the community bridge, Koog Edge, is early and targets other engines.

The seam Koog leaves you is `PromptExecutor`. Implement it, and everything above is Koog, everything below is your engine. Koog builds the prompt and owns the agent; LiteRT-LM generates from a Gemma file in the app's storage.

```kotlin
private class LiteRtPromptExecutor(private val engine: () -> ChatEngine?) : PromptExecutor() {
    override suspend fun execute(prompt: Prompt, model: LLModel, tools: List<ToolDescriptor>) =
        Message.Assistant(content = generate(prompt, model), metaInfo = ResponseMetaInfo.Empty)

    private suspend fun generate(prompt: Prompt, model: LLModel): String {
        val active = engine() ?: error("No model is loaded on this device")
        // Koog's prompt is typed messages; LiteRT-LM wants a system instruction and one user turn.
        val system = prompt.messages.filterIsInstance<Message.System>().joinToString("\n") { it.textContent() }
        val body = prompt.messages.filterNot { it is Message.System }.joinToString("\n") { it.textContent() }
        return active.reply(ReplySpec(system = system, prompt = body, ...)).lastOrNull().orEmpty()
    }
}
```

Each character is then an ordinary `AIAgent` with its own system prompt and a sixty-four-token reply budget. Now you see why the Android app became a group chat. On iOS, tool calling was free, so I built around tools. On Android, with my own executor, what I had cheaply was many personas on one model, so I built around personas. The platform shaped the product. That is honest engineering, but know it before you promise feature parity.

---

## The error that kept finding me

`exceededContextWindowSize`. Apple's engineers said on the forums that the window is 4,096 tokens and fixed. On the iOS 27 simulator the error itself told me the ceiling was 8,192, so it has grown, but it is still a wall. Everything in a session counts: instructions, every prompt, every reply, every tool schema, and the input and output of every tool call.

Now picture a standings table. Twenty teams, each with a rank, a name, a record, points, games played. My first tool returned something close to the raw structure. One call ate half the window; the third question threw. The error even reports a count slightly over the limit, which confused me until I understood it reports the count at the moment it tripped.

Four things fixed it.

**Make the tools terse.** One compact line per team, grouped, nothing else. No JSON, no field names.

```swift
var line = "\(row.rank.map { "\($0). " } ?? "")\(row.team) \(row.record)"
if let points = row.points { line += ", \(points) pts" }
```

**Tell the model it need not repeat the table.** The instructions say the app shows the full table under the reply, so summarise. The model is bad at tables and good at summaries; the app is good at tables.

**Keep the guardrail out of the main session.** The classifier runs in its own short-lived session and never adds to the conversation's transcript.

**Catch the error and rebuild the session.** A long enough chat will still fill the window, and here is the part the documentation did not prepare me for: once it does, the session never recovers. I asked for the full table eleven times in a row on the iOS 27 simulator. The eleventh overflowed, and the twelfth and thirteenth failed with the same error before the model had read a word. The session is finished until you make a new one.

Apple's technote on managing the context window says to condense and continue; what you keep is your call. I keep only the instructions. The tools can fetch any fact again more cheaply than the transcript can carry it.

```swift
func respond(to message: String) async throws -> Reply {
    do {
        return try await send(message)
    } catch where Self.isContextOverflow(error) {
        session = Self.makeSession(league: league, store: store, transcript: condensedTranscript())
        return try await send(message)
    }
}

private static func isContextOverflow(_ error: any Error) -> Bool {
    if #available(iOS 27, *), case LanguageModelError.contextSizeExceeded = error { return true }
    if case LanguageModelSession.GenerationError.exceededContextWindowSize = error { return true }
    if let toolError = error as? LanguageModelSession.ToolCallError {
        return isContextOverflow(toolError.underlyingError)
    }
    return false
}
```

Why two names? Because my first version caught only `GenerationError.exceededContextWindowSize`, the case in every tutorial, and the simulator walked straight past it. iOS 27 deprecates that case and throws `LanguageModelError.contextSizeExceeded` instead, which at least carries the window size and the token count that tripped it. A catch written from the documentation matched nothing, the user saw an error bubble, and the chat was dead. Check which error your SDK actually throws before you trust the catch. And do not hard-code the number either: `SystemLanguageModel.default.contextSize` will tell you the window on the device you are actually running on.

With the first three fixes, eight ordinary questions, three of them full tables, never came near the limit. The fourth fix is for the user who keeps going. With it in place I ran the eleven-table test again: the eleventh question overflowed, the agent rebuilt the session from a transcript of forty-one entries, and the eleventh, twelfth and thirteenth were all answered. The user loses the earlier turns, not the answer.

On Android the problem is the same with a different number. The Banter characters see only the last two messages of the chat. It sounds brutal. It is also why three of them can take turns on a phone without it crawling.

---

## Agents as a Service

Around the fourth weekend I stopped thinking of the agent as "the AI part" and started treating it as a service, like a payments service or a sync service. I call this **Agents as a Service**, AGAS, and it changed how I lay out an app.

**The contract.** An agent service takes a message and returns a reply with provenance: what it said and what it did to say it.

```swift
struct Reply {
    let text: String
    let toolsUsed: [String]
}
```

On iOS the agent reads the transcript after each turn and reports the tool calls. The view model then fetches the same rows the tool saw and draws them as a table. The model wrote prose; the app drew data. On Android the contract is one domain interface, `Voices`, with one method, and the turn loop above it is pure Kotlin tested against a fake that needs no model.

**Where it sits.** The same shape on both platforms:

```
ui ─ screens, bubbles, tables
      │ view model
AGENT SERVICE ─ interface in the domain
      one session or agent per context (league, persona)
      guardrail as its own tiny agent
      context budget owned here (condense, retry)
      reply = text + provenance
      │ tools are the only door
REPOSITORY ─ "cache or network?" decided once
      local rows · freshness rule
      │
API LAYER ─ generic GET + decode, errors, network monitor
```

**Integrating with the API layer.** The temptation is to let a tool call the API. Do not. A tool calls the repository, and the repository decides between local rows and the network. In the iOS app, `LeagueStore` is the only type that knows both SwiftData and the API. This gives you three things at once: the agent works offline because the repository already does; the rows the tool saw are in the database for the UI to draw; and the API layer stays boring and does not know an agent exists. Three shapes per kind of data keep it clean: the API's shape decoded as-is, the app's flat shape, and the database row.

**One agent per context.** One session per league on iOS, discarded when you leave. One Koog agent per character on Android, keyed by a fingerprint of its system prompt so an edited profile gets a fresh one. Small models do better with a narrow job and a short memory.

**The budget belongs to the service.** Nobody above it should know there is a context window, or that there is no model on this phone. The service condenses and retries, or reports that it is not ready and the UI closes the composer.

**The ladder.** Once the agent is behind an interface, the on-device agent is one implementation and a cloud agent is another, with a small policy choosing between them. An earlier installment in this series built exactly that router between Gemini Nano and a cloud model. Neither Banter has a cloud implementation, by choice. The seam is there.

If you take one thing from this section: the agent is a service, tools are its only door to your data, and the repository behind that door is what makes offline work.

---

## Take the code

Both repositories are building blocks rather than finished products.

[**Banter for iOS**](https://github.com/AziwaSensei/Banter-iOS): one session per league, three tools, a structured-output guardrail, a cache-first store over SwiftData, and the context-window recovery above. Swap the league enum and the two ESPN fetches for your own domain and most of it stands.

[**Banter for Android**](https://github.com/AziwaSensei/OfflineBanterChat): a `PromptExecutor` over LiteRT-LM, one Koog agent per persona, a fully unit-tested turn loop, Room and DataStore for storage, and a model screen honest about licence-gated downloads. The UI shares its shapes and colours with the iOS app.

Clone them, break them, tell me what you find.

---

## Where I have arrived

Paul still knows more than my phone does, and he always will. But the phone now answers quickly, in the places he is not, and sends my questions nowhere.

What stays with me is not the model. A small model with a tiny window forced me to be disciplined about what an agent is, where it lives, what it may touch, and how it reports what it did. The models will be bigger next year. The window will grow. The discipline should not shrink.

If you build one of these, start offline. It teaches you things the cloud lets you avoid.

---

*Written by Ali Ziwa. The AI in Mobile series continues weekly.*

**Sources**

- [Apple Developer Forums on the fixed 4,096-token limit](https://developer.apple.com/forums/thread/806542)
- [Apple Technote TN3193, Managing the on-device foundation model's context window](https://developer.apple.com/documentation/technotes/tn3193-managing-the-on-device-foundation-model-s-context-window)
- [Google, ML Kit GenAI Prompt API](https://developers.google.com/ml-kit/genai/prompt/android/get-started)
- [Google, LiteRT-LM](https://developers.googleblog.com/blazing-fast-on-device-genai-with-litert-lm/)
- [JetBrains Koog](https://github.com/JetBrains/koog) and [issue 262 on Android local models](https://github.com/JetBrains/koog/issues/262)
- [Koog Edge](https://github.com/lemcoder/koog-edge)
- [Gemma 4 E2B for LiteRT-LM](https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm)
