# Contributing

Contributing to OpenGamepadUI is done via Pull Requests on the main github repository: [OpenGamepadUI](https://github.com/shadowblip/OpenGamepadUI).

## Commit Titles

This project uses [semantic-release](https://github.com/semantic-release/semantic-release) which uses Angular-style commit messages in order to automatically trigger releases.

You can read more about it [here](https://github.com/angular/angular/blob/main/CONTRIBUTING.md#-commit-message-format).

In short every commit must be in the form of:

- chore(*thing*): Title words
- fix(*thing*): Title words
- feat(*thing*): Title words
- docs(*thing*): Title words

This is a non-exhaustive list, please read the above link to learn more.

## AI/Tool-generated Content

Contributions authored using code generation tools like large language models
_may_ be accepted, but **must** be clearly disclosed as part of the commit message(s)
that contain generated code and you must be prepared to explain every line that
was generated. Contributions submitted that used generated content _without_
disclosure may be rejected without review. Accepted code may be reverted if AI
tools were discovered to have been used after inclusion and users found to be
flagrantly violating this policy after a warning are subject to a ban from the
project.

You can disclose tool use by including something like this in the body of your commit message: 

```
Assisted-by: LLM
```

Do not include the name or product of the LLM used in your commit message; we
do not want to advertise any given LLM company or product. Instead just include
the `Assisted-by: LLM` annotation.

You should also elaborate on which parts were generated, what prompts you used, etc.

Before submitting your PR, you must ensure that you have fully reviewed and tested the
changes you submit.

Using AI to respond to human reviewers is strictly prohibited.
