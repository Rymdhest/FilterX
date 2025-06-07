# FilterX

<div align="center">
  <img src="screenshots/FilterX filter window.png" alt="FilterX Filter Edit" width="400px" />
  <img src="screenshots/FilterX rule window.png" alt="FilterX Rule Edit" width="400px" />
</div>

---

## Release

Download the latest version of FilterX here:  
[FilterX v1.0.0 Download](https://github.com/rymdhest/FilterX/releases/latest)

---

FilterX is a World of Warcraft 3.3.5 loot filter addon that empowers players to create customizable filters to manage their loot automatically. With FilterX, you can define detailed rules to decide what happens to each item you loot, streamlining your gameplay and inventory management.

---

## Features

- **Custom Filters & Rules**  
  Create multiple filters, each containing rules based on:  
  - Item level range  
  - Item quality  
  - Item classes and subclasses  
  - Bind on pickup status  
  - Usability  
  - Whether the item is already learned  
  - Item name contains specific words  
  - Exact item lists  

- **Rule Actions**  
  Each rule can perform one of the following actions on matching items, in priority order:  
  1. Do nothing  
  2. Sell  
  3. Disenchant  
  4. Delete  
  5. Keep  

- **Alerts**  
  Attach alerts to rules to receive popup notifications when an item triggers a rule.

- **Automation**  
  - Items manually sold or disenchanted by the player are automatically added to the corresponding sell or disenchant rules.  
  - When visiting a vendor, all items marked for selling are automatically sold.  
  - A dedicated disenchant UI with a button to disenchant all items marked for disenchant in your inventory.

- **Tooltip Integration**  
  When mousing over an item, the tooltip shows the action FilterX will perform and which rule triggered it.

- **Slash Commands**  
  Access the addon interface with any of these commands:  
  `/filterx`, `/fx`, or `/lootfilter`

- **Import/Export**  
  Easily share filters by importing and exporting them between players.

---

## Installation

1. Download the latest release ZIP file.  
2. Extract the folder named `FilterX` into your World of Warcraft `Interface/AddOns` directory.  
3. Restart WoW or reload the UI with `/reload`.

---

## Usage

- Open the main FilterX window using `/filterx`, `/fx`, or `/lootfilter`.  
- Create filters and add rules with desired conditions and actions.  
- Use the vendor and disenchant automation features to manage your inventory effortlessly.  
- Hover over items to see what FilterX will do with them.

---

## Contributing

Contributions and feedback are welcome! Feel free to open issues or submit pull requests.

---

## License

This project is licensed under the MIT License.
