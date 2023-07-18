# Glossary Extension For Quarto

Add a glossary to your document.

## Installing

```bash
quarto add andrewpbray/glossary
```

This will install the extension under the `_extensions` subdirectory.
If you're using version control, you will want to check in this directory.

## Using

Creating the glossary consists of three steps:

1. Activate the filter
2. Define location of glossary
3. Specify glossary contents

#### 1. Activate the filter

The filter can be activated on a document through the `filters` key in the YAML metadata.

```yaml
---
filters:
  - glossary
---
```

#### 2. Define location of glossary

The glossary can be added anywhere in the document by inserting a block with a unique id of your choosing. Here, that id is `my-glossary`.

```
The glossary will appear below this line of text.

:::{#my-glossary}
:::

Here is some more text in the document.
```

#### 3. Specify glossary contents

The content that will fill in your new glossary block are specified in the document metadata through the `glossary` key, which has three options: `id`, `class`, and `contents`. As an example:

```yaml
---
filters:
  - glossary
glossary:
  id: my-glossary
  class: definition
  contents:
    - "ex*"
---
```

This specifies that the glossary with the id of `my-glossary` will contain any blocks that have the class `definition` within all files in the document (or project) working directory that begin with `ex`. Note some details about each of these options:

- `id`: a valid YAML string that matches the id of the block that you created in step 1. In the creation of the block, the id is begins with `#` but here in the option the `#` is omitted. Note that certain id prefixes like `def-list` and `thm-set` will trigger Quarto to add in cross-references (which is likely undesirable in this implementation of a glossary). See the [cross-references documentation](https://quarto.org/docs/authoring/cross-references.html#theorems-and-proofs) for affected prefixes.

- `class`: a valid YAML string that matches the class of any blocks in any targeted documents that you wish you include in the glossary. As an example, see `ex-animals.qmd`, where there appear two blocks with the `.definition` class. When adding the class to a block, the class name begins with a `.` but in the YAML option here the `.` is omitted.

- `contents:` A list of files to scan through for blocks that meet the specified class. These can be a YAML list of full file paths (ending in `.qmd`, `.md`, or `.ipynb`) or include globs, as in the example here, to indicate multiple files (`"ex*"` matches both `ex-plants.qmd` and `ex-animals.qmd`).

## Example

Here is the source code for a minimal example: [example.qmd](example.qmd).

