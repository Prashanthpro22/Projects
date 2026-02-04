#!/usr/bin/env python3
import sys
import pandas as pd

def main():
    if len(sys.argv) != 3:
        print("Usage: python split_component_to_columns.py <input.csv> <output.csv>")
        sys.exit(1)

    inp = sys.argv[1]
    out = sys.argv[2]

    df = pd.read_csv(inp)

    # Expect columns: Frequency (or Frequency_Hz), Component (I/Q), P0, P1, ..., P127
    freq_col = df.columns[0]

    if "Component" not in df.columns:
        raise ValueError("Input CSV must contain a 'Component' column with values I and Q")

    # All pulse columns are everything except frequency and Component
    pulse_cols = [c for c in df.columns if c not in [freq_col, "Component"]]

    # Split I and Q rows
    df_I = df[df["Component"].str.upper() == "I"].copy()
    df_Q = df[df["Component"].str.upper() == "Q"].copy()

    # Sanity checks
    if len(df_I) != len(df_Q):
        raise ValueError("Mismatch in number of I and Q rows. Input data is inconsistent.")

    if not df_I[freq_col].reset_index(drop=True).equals(df_Q[freq_col].reset_index(drop=True)):
        raise ValueError("Frequency rows for I and Q do not align. Input data is inconsistent.")

    # Build output starting with frequency
    out_df = pd.DataFrame()
    out_df[freq_col] = df_I[freq_col].values

    # For each pulse column Px, create Px_I and Px_Q
    for p in pulse_cols:
        out_df[f"{p}_I"] = df_I[p].values
        out_df[f"{p}_Q"] = df_Q[p].values

    # Save
    out_df.to_csv(out, index=False)
    print(f"Saved: {out}")

if __name__ == "__main__":
    main()
