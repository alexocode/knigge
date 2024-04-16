# Contributing

If you discover issues, have ideas for improvements or new features,
please [open an issue](https://github.com/alexocode/knigge/issues)
or submit a pull request.

Make sure to follow the following guidelines when doing so.

## Issue Reporting

* Check that the issue has not already been reported.
* Check that the issue has not already been fixed in the latest changes
  (a.k.a. `main`).
* Be clear, concise and precise in your description of the problem.
* Open an issue with a descriptive title and a summary in grammatically correct,
  complete sentences.

## Pull Requests

* Read [how to properly contribute to open source projects on GitHub](https://www.gun.io/blog/how-to-github-fork-branch-and-pull-request).
* Fork the project.
* Use a topic/feature branch so you're able to make additional changes later, if necessary.
* Write [good commit messages](https://chris.beams.io/posts/git-commit/).
* Use the same coding conventions as the rest of the project.
* Commit and push until you are happy with your contribution.
* Make sure to add tests for it. So we can avoid that it breaks accidentially in the future.
* Add an entry to the [Changelog](./CHANGELOG.md) accordingly. See [changelog entry format](#changelog-entry-format).
* Open a [pull request](https://help.github.com/articles/about-pull-requests) that relates to *only* one subject with a clear title
  and description in grammatically correct, complete sentences.

### Changelog Entry Format

Here are a few examples:

```
- [#19](https://github.com/alexocode/knigge/pull/19): Fix handling of callbacks without brackets ([@NickNeck])
- [#16](https://github.com/alexocode/knigge/pull/16): Migrate CI from CircleCI to GitHub actions ([@alexocode])
- [#15](https://github.com/alexocode/knigge/pull/15): Add `--app` switch to `mix knigge.verify` ([@polvalente])
```

* Mark it up in [Markdown syntax](https://daringfireball.net/projects/markdown/syntax).
* The entry line should start with `- ` (a dash and a space).
* Begin with a link to your pull request (`[#456](https://github.com/alexocode/knigge/pull/456): `)
* Describe the core idea of the change. The sentence should end with punctuation.
* If this is a breaking change, mark it with `**(Breaking)**`.
* At the end of the entry, add an implicit link to your GitHub user page as `([@username])`.
* If this is your first contribution to Knigge, add a link definition for the implicit link to the bottom of the changelog as `[@username]: https://github.com/username`.

*These guidelines were inspired by the [contribution guidelines of the rubocop project](https://github.com/rubocop/rubocop/blob/master/CONTRIBUTING.md).*
