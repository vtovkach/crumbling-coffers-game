# Crumbling Coffers  

---

## Table of Contents
* [Description](#description)
* [General Info](#general-information)
* [Technologies Used](#technologies-used)

---

![Crumbling Coffers Title Page](docs/screenshots/crumbling-coffers-title-page.png)

<div id="description"></div>

## Description

**Team:** Aurora Blakely, Andrea Gomez, Daniel Pelley, Nicholas Krustchinsky, Vadym Tovkach  

**Concept:** A competitive multiplayer Metroidvania-style platformer centered around nonlinear exploration, strategic item collection, and time-based scoring. Players navigate interconnected levels filled with movement challenges, hidden paths, and unlockable abilities that expand traversal options as the match progresses. Each session emphasizes speed, routing efficiency, and smart decision-making, rewarding players not just for collecting items, but for optimizing their path and adapting to opponents in real time. The result is a fast-paced experience that blends precision platforming with competitive depth and replayability.  

**Audience:** Fans of metroidvania platformers and pixel art who enjoy competitive and fun video games.  

**Purpose:** To create a competitive and visually engaging game for friends  

---

<div id="general-information"></div>

## General Information

**Crumbling Coffers** is a multiplayer platformer inspired by Metroidvania design principles.

The game features a large vertically explorable map filled with caves and interconnected areas. Players can traverse upward and downward freely, discovering items scattered across the environment.

The core objective is competitive collection:
- Up to **4 active players** compete within the same map.
- Items have different **rarity tiers** and **score values**.
- Matches are **time-based**.
- After time expires, a **scoreboard** displays all collected items and calculates each player's total score.

The game also includes temporary **boost items (spells)** that enhance abilities such as stamina, speed, and jump height, adding strategic depth to exploration and competition.

--- 

<div id="technologies-used"></div>

## Technologies Used

- **Godot Engine** – Rendering, physics, scene management, and cross-platform support.
- **GDScript (Client)** – Gameplay logic, input handling, UI, client-side prediction and interpolation.
- **C (Dedicated Server)** – Authoritative server handling networking, simulation ticks, session management, and state synchronization.
 
---