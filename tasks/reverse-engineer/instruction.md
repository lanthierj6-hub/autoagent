# Reverse Engineer the Algorithm

You are given a mysterious black-box function's input/output pairs in `files/samples.json`. Your job is to reverse-engineer the algorithm and implement it.

## Input
`files/samples.json` contains 20 input/output pairs. Each input is a dictionary with various fields. The output is always a dictionary.

## Your Task
1. Study ALL 20 samples carefully to deduce the transformation rules
2. Implement the algorithm in Python
3. Apply it to `files/test_inputs.json` (10 new inputs)
4. Write results to `/task/output/test_outputs.json`

## Output Format
`/task/output/test_outputs.json` must be a JSON array of 10 objects, one per test input, in the same order.

## Hints
- The algorithm involves multiple transformation steps applied in sequence
- Some rules depend on the VALUES of fields (conditionals)
- Some rules involve cross-field computation
- There is exactly ONE correct algorithm that produces all 20 sample outputs
- Pay attention to edge cases in the samples — they reveal conditional branches

## Also produce
`/task/output/algorithm_description.txt` — A plain-text description of the algorithm you discovered (>200 bytes). This is graded for completeness.
