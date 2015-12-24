class Debunker::Prompt
  MAP = {
    "default" => {
      value: Debunker::DEFAULT_PROMPT,
      description: "The default Debunker prompt. Includes information about the\n" \
                   "current expression number, evaluation context, and nesting\n" \
                   "level, plus a reminder that you're using Debunker."
    },

    "simple" => {
      value: Debunker::SIMPLE_PROMPT,
      description: "A simple '>>'."
    },

    "nav" => {
      value: Debunker::NAV_PROMPT,
      description: "A prompt that displays the binding stack as a path and\n" \
                   "includes information about _in_ and _out_."
    },

    "none" => {
      value: Debunker::NO_PROMPT,
      description: "Wave goodbye to the Debunker prompt."
    }
 }
end
