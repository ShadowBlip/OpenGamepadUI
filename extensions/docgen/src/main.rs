use std::{collections::HashSet, env, fs, path::Path, process};

use regex::Regex;

fn main() {
    // Read the source directory from the cli args
    let args: Vec<String> = env::args().collect();
    if args.len() < 3 {
        print_help();
        process::exit(-1);
    }

    // Parse the arguments
    let definition_dir = args.get(1).unwrap();
    let output_dir = args.get(2).unwrap();

    // Read the class definition files
    let readdir = match fs::read_dir(definition_dir) {
        Ok(value) => value,
        Err(e) => {
            print_help();
            println!("Failed to read directory {definition_dir}: {e}");
            process::exit(-1);
        }
    };

    // Read each directory entry
    let mut entries = Vec::new();
    for entry in readdir {
        let Ok(entry) = entry else {
            continue;
        };
        entries.push(entry);
    }

    // Build a list of classes and navigation tree
    let mut classdb = HashSet::new();
    for entry in entries.iter() {
        let filename = entry.file_name().to_string_lossy().to_string();
        let class_name = filename.replace(".xml", "");
        classdb.insert(class_name.clone());
    }

    // Parse each XML definition
    for entry in entries.iter() {
        let path = entry.path();
        let Some(markdown) = parse_class(&classdb, path.as_path()) else {
            continue;
        };

        // Write the markdown to the output directory
        let filename = entry.file_name().to_string_lossy().to_string();
        let class_name = filename.replace(".xml", "");
        let out_path = format!("{output_dir}/{class_name}.md");
        println!("Writing class reference for '{class_name}' to: {out_path}");
        fs::write(out_path, markdown).expect("Write should succeed");
    }

    // Write out the navigation tree
    let mut nav_tree = "nav:\n".to_string();
    let nav_tree_path = format!("{output_dir}/.nav.yml");
    let mut sorted_classes: Vec<String> = classdb.into_iter().collect();
    sorted_classes.sort();
    for class in sorted_classes {
        nav_tree.push_line(format!("  - ./{class}.md"));
    }
    fs::write(nav_tree_path, nav_tree).expect("Write should succeed");
}

fn parse_class(classdb: &HashSet<String>, path: &Path) -> Option<String> {
    let data = match fs::read_to_string(path) {
        Ok(value) => value,
        Err(e) => {
            println!("Failed to read XML {path:?}: {e}");
            process::exit(-1);
        }
    };
    let doc = match roxmltree::Document::parse(data.as_str()) {
        Ok(value) => value,
        Err(e) => {
            println!("Failed to parse XML {path:?}: {e}");
            process::exit(-1);
        }
    };

    // Generate markdown for the file
    let mut markdown = String::new();
    let class = doc.descendants().find(|v| v.tag_name().name() == "class")?;
    let class_name = class.attribute("name")?;

    // Title
    markdown.push_line(format!("# {class_name}\n"));

    // Inherits
    if let Some(inherits) = class.attribute("inherits") {
        let inherits_link = get_class_link_text_for(classdb, inherits);
        markdown.push_line(format!("**Inherits:** {inherits_link}\n"));
    }

    // Brief
    let brief = class
        .children()
        .find(|node| node.tag_name().name() == "brief_description");
    if let Some(brief) = brief {
        if let Some(brief) = brief.text() {
            let brief = parse_text_links(classdb, brief.trim());
            markdown.push_line(brief);
        }
    }

    // Description
    let desc = class
        .children()
        .find(|node| node.tag_name().name() == "description");
    if let Some(desc) = desc {
        if let Some(desc) = desc.text() {
            let desc = parse_text_links(classdb, desc.trim());
            if !desc.is_empty() {
                markdown.push_line("## Description\n".to_string());
                markdown.push_line(desc);
            }
        }
    }

    // Find all valid property nodes
    let props = {
        let mut nodes = vec![];
        let props = class
            .children()
            .find(|node| node.tag_name().name() == "members");
        if let Some(props) = props {
            for child in props.children() {
                let Some(name) = child.attribute("name") else {
                    continue;
                };
                // Skip private variables
                if name.starts_with("_") {
                    continue;
                }
                if !child.has_attribute("type") {
                    continue;
                };
                nodes.push(child);
            }
        }

        nodes
    };

    // Find all valid method nodes
    let methods = {
        let mut nodes = vec![];
        let methods = class
            .children()
            .find(|node| node.tag_name().name() == "methods");
        if let Some(methods) = methods {
            for child in methods.children() {
                let Some(name) = child.attribute("name") else {
                    continue;
                };
                // Skip private methods
                if name.starts_with("_") {
                    continue;
                }
                nodes.push(child);
            }
        }

        nodes
    };

    // Properties
    if !props.is_empty() {
        markdown.push_line("## Properties\n".to_string());
        markdown.push_str("| Type | Name | Default |\n");
        markdown.push_str("| ---- | ---- | ------- |\n");
        for child in props.iter() {
            let Some(name) = child.attribute("name") else {
                continue;
            };
            let Some(kind) = child.attribute("type") else {
                continue;
            };
            let default = child.attribute("default").unwrap_or("");
            let kind = get_class_link_text_for(classdb, kind);
            markdown.push_line(format!("| {kind} | [{name}](./#{name}) | {default} |"));
        }
        markdown.push('\n');
    }

    // Methods
    if !methods.is_empty() {
        markdown.push_line("## Methods\n".to_string());
        markdown.push_str("| Returns | Signature |\n");
        markdown.push_str("| ------- | --------- |\n");

        for child in methods.iter() {
            let Some(name) = child.attribute("name") else {
                continue;
            };
            // Skip private methods
            if name.starts_with("_") {
                continue;
            }
            let returns = child
                .children()
                .find(|node| node.tag_name().name() == "return")
                .unwrap();
            let return_type = returns.attribute("type").unwrap();
            let return_type = get_class_link_text_for(classdb, return_type);

            // Parse arguments
            let mut args = Vec::new();
            for child in child.children() {
                if child.tag_name().name() != "param" {
                    continue;
                }
                let Some(name) = child.attribute("name") else {
                    continue;
                };
                let Some(kind) = child.attribute("type") else {
                    continue;
                };
                let default = if let Some(default) = child.attribute("default") {
                    format!(" = {default}")
                } else {
                    "".to_string()
                };
                let kind = get_class_link_text_for(classdb, kind);
                let arg_sig = format!("{name}: {kind}{default}");
                args.push(arg_sig);
            }
            let args = args.join(", ");

            markdown.push_line(format!("| {return_type} | [{name}](./#{name})({args}) |"));
        }
    }

    // Signals

    // Enumerations

    // Property Descriptions
    if !props.is_empty() {
        markdown.push_str("\n\n------------------\n\n");
        markdown.push_str("## Property Descriptions\n\n");

        for child in props.iter() {
            let Some(name) = child.attribute("name") else {
                continue;
            };
            let Some(kind) = child.attribute("type") else {
                continue;
            };
            let default = child.attribute("default").unwrap_or("");
            let desc = child.text().unwrap_or("").trim();
            let desc = parse_text_links(classdb, desc);
            let kind = get_class_link_text_for(classdb, kind);
            let default = default.trim();
            let default = if !default.is_empty() && !default.starts_with("<") {
                format!(" = <span style=\"color: red;\">{default}</span>")
            } else {
                "".to_string()
            };

            markdown.push_line(format!("### `{name}`\n\n"));
            markdown.push_line(format!("{kind} {name}{default}\n\n"));
            if !desc.is_empty() {
                markdown.push_line(desc);
            } else {
                markdown.push_str("!!! note\n");
                markdown.push_str("    There is currently no description for this property. Please help us by contributing one!\n\n");
            }
        }
        markdown.push('\n');
    }

    // Method Descriptions
    if !methods.is_empty() {
        markdown.push_str("\n\n------------------\n\n");
        markdown.push_str("## Method Descriptions\n\n");
        for child in methods.iter() {
            let Some(name) = child.attribute("name") else {
                continue;
            };
            // Skip private methods
            if name.starts_with("_") {
                continue;
            }
            let returns = child
                .children()
                .find(|node| node.tag_name().name() == "return")
                .unwrap();
            let return_type = returns.attribute("type").unwrap();
            let return_type = get_class_link_text_for(classdb, return_type);

            // Description
            let desc = child
                .children()
                .find(|node| node.tag_name().name() == "description");
            let desc = if let Some(desc) = desc {
                let text = desc.text().unwrap_or("").trim();
                parse_text_links(classdb, text)
            } else {
                "".to_string()
            };

            // Parse arguments
            let mut args = Vec::new();
            for child in child.children() {
                if child.tag_name().name() != "param" {
                    continue;
                }
                let Some(name) = child.attribute("name") else {
                    continue;
                };
                let Some(kind) = child.attribute("type") else {
                    continue;
                };
                let default = if let Some(default) = child.attribute("default") {
                    format!(" = {default}")
                } else {
                    "".to_string()
                };
                let kind = get_class_link_text_for(classdb, kind);
                let arg_sig = format!("{name}: {kind}{default}");
                args.push(arg_sig);
            }
            let args = args.join(", ");

            markdown.push_line(format!("### `{name}()`\n\n"));
            markdown.push_line(format!("{return_type} **{name}**({args})\n\n"));
            if !desc.is_empty() {
                markdown.push_line(desc);
            } else {
                markdown.push_str("!!! note\n");
                markdown.push_str("    There is currently no description for this method. Please help us by contributing one!\n\n");
            }
        }
    }

    Some(markdown)
}

fn get_class_link_text_for(classdb: &HashSet<String>, text: &str) -> String {
    if text == "void" {
        return "void".to_string();
    }
    if text == "br" {
        return "\n".to_string();
    }
    if text == "DEPRECATED" {
        return "!!! warning\n\n    This is deprecated\n\n".to_string();
    }
    // If the class ends in '[]', then its an array of a type
    if text.ends_with("[]") {
        let class_name = text.replace("[]", "");
        let link = get_class_link_for(classdb, class_name.as_str());
        return format!("[{text}]({link})");
    }
    // If the class has container types, just use the base class
    if text.contains("[") && text.ends_with("]") {
        let mut parts = text.split("[");
        let class_name = parts.next().unwrap();
        let link = get_class_link_for(classdb, class_name);
        return format!("[{text}]({link})");
    }
    let link = get_class_link_for(classdb, text);
    format!("[{text}]({link})")
}

fn get_class_link_for(classdb: &HashSet<String>, class_name: &str) -> String {
    // Check to see if this is a local class
    if classdb.contains(class_name) {
        return format!("../{class_name}");
    }
    // Otherwise assume this is a Godot class
    let class_name_lower = class_name.to_lowercase();
    format!("https://docs.godotengine.org/en/stable/classes/class_{class_name_lower}.html")
}

// Search for any "[SomeClass]" references and replace them with links
fn parse_text_links(classdb: &HashSet<String>, text: &str) -> String {
    // First find any codeblocks and escape the characters that might match link
    // patterns.
    let codeblock_pattern = Regex::new(r"\[codeblock\][.\n\t\s\S]*?\[/codeblock\]").unwrap();
    let mut code_matches = HashSet::new();
    for item in codeblock_pattern.find_iter(text) {
        code_matches.insert(item.as_str());
    }

    // Escape all the '[' and ']' patterns so the next step doesn't replace
    // code block content.
    let mut escaped_text = text.to_string();
    for original_text in code_matches {
        let new_text = original_text
            .replace("[", "<<{;{;{")
            .replace("]", "};};}>>");
        escaped_text = escaped_text.replace(original_text, &new_text);
    }

    // Find any links with the pattern "[MyClass]" in the text
    let link_pattern = Regex::new(r"\[.*?\]").unwrap();
    let mut matches = HashSet::new();
    for item in link_pattern.find_iter(escaped_text.as_str()) {
        matches.insert(item.as_str());
    }

    // Replace each instance with the class link
    let mut replaced_text = escaped_text.clone();
    for item in matches {
        let class_name = item.strip_prefix("[").unwrap().strip_suffix("]").unwrap();
        let link = get_class_link_text_for(classdb, class_name);
        replaced_text = replaced_text.replace(item, link.as_str());
    }

    // Restore the escaped sequences
    replaced_text = replaced_text
        .replace("<<{;{;{", "[")
        .replace("};};}>>", "]");

    // Convert the codeblocks to markdown
    replaced_text = replaced_text
        .replace("[codeblock]", "```gdscript\n")
        .replace("[/codeblock]", "```\n\n");

    replaced_text
}

fn print_help() {
    println!("Usage: docgen [class XML definition directory] [output dir]");
    println!();
    println!("Example:");
    println!("  docgen ./docs/api/classes ./docs/class-reference");
}

trait LinePusher {
    fn push_line(&mut self, line: String);
}

impl LinePusher for String {
    fn push_line(&mut self, line: String) {
        self.push_str(line.as_str());
        self.push('\n');
    }
}
