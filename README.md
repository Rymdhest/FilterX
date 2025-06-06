# FilterX: Advanced Loot Filtering Addon for WoW 3.3.5

FilterX is a powerful and customizable loot filter addon for World of Warcraft 3.3.5. It empowers players to automate and fine-tune their loot management by creating flexible filters with detailed rule sets and automated actions.

---

## Table of Contents

- [Download](#download)
- [Features](#features)
- [How It Works](#how-it-works)
- [Installation](#installation)
- [Usage](#usage)
- [Importing & Exporting Filters](#importing--exporting-filters)
- [Contributing](#contributing)
- [License](#license)

---

## Download

Get the latest stable release here:

[Download FilterX v1.0.0](https://github.com/Rymdhest/FilterX/releases/download/v1.0.0/FilterX.zip)

---

## Features

- **Custom Filters:** Create unlimited filters, each with its own set of rules.
- **Comprehensive Rule Types:**
  - Item level range
  - Item quality
  - Item class/subclass
  - Bind on pickup status
  - Usability (usable by your character)
  - Already learned status
  - Name contains specific words
  - Exact item matches
- **Automated Actions:** Assign actions to rules:
  - Do nothing
  - Sell
  - Disenchant
  - Delete
  - Keep  
  (Actions are prioritized: Do nothing > Sell > Disenchant > Delete > Keep)
- **Alerts:** Attach customizable alert popups to any rule that triggers.
- **Smart Learning:** Items manually sold or disenchanted can be auto-added to the respective rules.
- **Vendor Automation:** Instantly sell all items marked for selling when visiting a vendor.
- **Disenchant UI:** Dedicated UI and button to disenchant all marked items in your inventory.
- **Easy Sharing:** Import and export filters to share setups with other players.

---

## How It Works

1. **Create Filters:** Organize your loot management by grouping rules into filters.
2. **Define Rules:** Specify criteria for each rule using item properties or exact matches.
3. **Assign Actions:** Decide what happens when an item matches a rule.
4. **Automate:** Let FilterX handle selling, disenchanting, deleting, or keeping items based on your filters.
5. **Get Alerts:** Receive popups for important loot drops, as configured in your rules.
6. **Smart Additions:** When you manually sell or disenchant an item, FilterX can automatically update your rules for future automation.

---

## Installation

1. Download the latest release of FilterX.
2. Extract the contents to your `World of Warcraft/Interface/AddOns/FilterX` directory.
3. Launch WoW and enable FilterX in the AddOns menu.

---

## Usage

- **Access FilterX:** Use the in-game commands or interface to open the FilterX configuration.
- **Creating Filters & Rules:**  
  - Add a new filter and define its rules.
  - Choose rule types and set criteria (e.g., item level, quality, etc.).
  - Assign actions and optional alerts.
- **Automatic Actions:**  
  - Visit a vendor to auto-sell marked items.
  - Use the Disenchant UI to disenchant all marked items with one click.
- **Manual Learning:**  
  - When you manually sell or disenchant, FilterX can prompt you to add the item to your rules for future automation.

---

## Importing & Exporting Filters

- **Export:** Share your filter setups with others using the export function.
- **Import:** Load filters from other players to quickly adopt their loot management strategies.

---

## Contributing

Contributions, bug reports, and feature requests are welcome! Please open an issue or submit a pull request.

---

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

---

**Last updated:** June 7, 2025
