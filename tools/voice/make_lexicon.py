"""Misaki's American English word lists as one small text file for the app:
python3 make_lexicon.py <us_gold.json> <us_silver.json> <out.tsv>

Each line is "word <tab> g|s <tab> sounds". g is the gold list (checked by hand), s the silver one
(checked less); the app looks in gold first, like Misaki. A word said differently as a noun, verb
and so on has "DEFAULT=...;NOUN=...;VERB=..." instead, where an empty value means "spell it out".
"""
import json
import sys


def rows(path, mark):
    with open(path, encoding="utf-8") as file:
        words = json.load(file)
    for word, sounds in words.items():
        assert not any(c in word for c in "\t\n"), repr(word)
        if isinstance(sounds, dict):
            assert "DEFAULT" in sounds, word
            parts = []
            for key in sorted(sounds, key=lambda k: (k != "DEFAULT", k)):
                value = sounds[key] or ""
                assert not any(c in value for c in "\t\n;="), (word, value)
                parts.append(f"{key}={value}")
            yield word, mark, ";".join(parts)
        else:
            assert sounds and not any(c in sounds for c in "\t\n;="), (word, sounds)
            yield word, mark, sounds


if __name__ == "__main__":
    gold_path, silver_path, target = sys.argv[1:4]
    lines = sorted(list(rows(gold_path, "g")) + list(rows(silver_path, "s")))
    with open(target, "w", encoding="utf-8") as file:
        file.write("# Misaki US English word lists (github.com/hexgrad/misaki, Apache-2.0), "
                   "made by tools/luna/make_lexicon.py\n")
        for word, mark, sounds in lines:
            file.write(f"{word}\t{mark}\t{sounds}\n")
    print(f"{len(lines)} words -> {target}")
