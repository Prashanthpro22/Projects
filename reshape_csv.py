#!/usr/bin/env python3
import pandas as pd
import sys

def main():
    if len(sys.argv) != 3:
        print("Usage: python reshape_csv.py <input.csv> <output.csv>")
        sys.exit(1)

    input_csv = sys.argv[1]
    output_csv = sys.argv[2]

    # Expect columns: Pulse, RangeBin, I, Q
    df = pd.read_csv(input_csv)

    required_cols = {"Pulse", "RangeBin", "I", "Q"}
    if not required_cols.issubset(df.columns):
        raise ValueError(f"Input CSV must contain columns: {required_cols}")

    # Pivot: rows = RangeBin, columns = Pulse, values = I and Q
    wide = df.pivot(index="RangeBin", columns="Pulse", values=["I", "Q"])

    # Order columns as: P0_I, P0_Q, P1_I, P1_Q, ...
    pulses = sorted(df["Pulse"].unique())
    cols = []
    for p in pulses:
        cols.append(("I", p))
        cols.append(("Q", p))

    wide = wide[cols]

    # Flatten column names
    wide.columns = [f"P{p}_{iq}" for iq, p in wide.columns]

    # Bring RangeBin back as a column
    wide = wide.reset_index()

    # Save output
    wide.to_csv(output_csv, index=False)
    print(f"Saved reshaped CSV to: {output_csv}")

if __name__ == "__main__":
    main()
