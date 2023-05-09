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
## Usage

### Creating Commands
Create a command definition file in the format `[command_name].json`. Then, install it to **JACT** using either of the following methods:

- Execute `$ jact install [command_name].json`
- Place the created JSON file in `(JACT root directory)/source`, then execute `$ jact refresh` or restart the shell.

### Writing JSON Command Definition Files
We provide a brief description of the **JACT** format, followed by an example.

#### Rules for Command Definition Files
**JACT** reads command definition files with these rules:

- The JSON file name is treated as the **command name**.
- JSON keys are divided into "regular keys" that have an object as a value and "special keys" that have a string as a value.
- Any JSON object element defines a subcommand corresponding to its key name.

##### Regular Keys
"Regular keys" have a non-empty object as their value and are treated as **subcommand names**. The value object represents the definition of that subcommand.

##### Special Keys
"Special keys" have a string as their value and define the behavior of a command (or subcommand) during execution or input completion. Special keys include:

- `__exec` key: Execution command.
- `__N` key: Completion command corresponding to the Nth argument of the execution command.
- `__default` key: A command executed instead of an error when there are insufficient arguments for the command specified by the `__exec` key.

##### Referencing External JSON Files
The value of a regular key (subcommand name) can also be an external JSON file specified as a string, with an absolute or relative path from that JSON file.

#### Example
Here is an example of a **JACT** command definition file:

```my-docker-util.json
{
    "__exec": "echo 'what a cute whale!!'",
    "create": {
        "__exec": "docker run -it -d --name {1} {0} bash",
        "__0": "echo ubuntu:18.04 debian:9 centos:7 node:14"
    },
    "connect": {
        "__exec": "docker exec -it {0} /bin/bash",
        "__0": "docker ps --format '{{.Names}}'"
    }
}
```

In this example,
`my-docker-util` is the command name, and by executing

```
$ my-docker-util
```

you will get the command result described in the `__exec` key directly below:
> what a cute whale!!

It has "create" and "connect" as subcommands. By executing

```
$ my-docker-util connect my-ubuntu-1
```

the subcommand "my-tools docker" will be called with arguments.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.