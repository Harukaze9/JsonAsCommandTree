# JACT (Json As Command Tree)

JACT is an open-source tool for bash and zsh shells designed to make it easy to navigate and manipulate JSON files using command-line. With JACT, you can easily:

- Pass arguments to your aliases
- Define input autocompletion for your aliases (or shell functions)
- Create hierarchical aliases

Using JACT is incredibly simple by just working with JSON files.

## Prerequisites

To use JACT, you need the following environment:

- Bash or Zsh shell
- Unix-based system (Linux, macOS)
- `jq` and `sed` commands installed

## Installation

Installing JACT is easy. Follow the steps below:

1. Clone this repository to your preferred location:

```
git clone https://github.com/Harukaze9/JsonAsCommandTree.git
```

2. Add the following line to your `.bashrc` or `.zshrc` file:

```bash
source /path/to/JsonAsCommandTree/source-jact.sh
```

3. Restart your shell or run `source ~/.bashrc` or `source ~/.zshrc`

## Usage

Create a JSON file with your desired command tree structure:

```json
{
  "example": {
    "command": "echo 'This is an example command'",
    "subcommands": {
      "subexample": {
        "command": "echo 'This is a subexample command'",
        "args": [
          {
            "name": "arg1",
            "description": "This is argument 1",
            "value": "default_value"
          }
        ]
      }
    }
  }
}
```

Then, load your JSON file using the `jact_load` function:

```bash
jact_load /path/to/your/json/file.json
```

Now, you can use your defined aliases:

```bash
example
example subexample
example subexample --arg1 custom_value
```

To enable autocompletion for your aliases, make sure to add `_jact_autocomplete` to your shell's completion system. For example, in Zsh:

```bash
compdef _jact_autocomplete example
```

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.