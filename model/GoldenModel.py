"""
================================================================================
Stream_Cipher_V1: Golden Model 
================================================================================
Authors: Federico Pucci, Giovanni Del Bianco
Date: 05/2026
Description:
    This script implements a custom stream cipher used as a "Golden Model" 
    for hardware verification (ModelSim). 

Operation:
    The cipher generates a keystream by indexing the standard AES S-box 
    using a sliding counter combined with a secret 8-bit key (K).
    The mathematical transformation for each byte is:
    
    C[i] = P[i] XOR Sbox[ (K + i) mod 256 ]

    Because the XOR operation is its own inverse, this script is used for 
    both ENCRYPTION and DECRYPTION. 

Outputs:
    1. Console output showing Hex and Text results.
    2. Two files in 'modelsim/tv/':
        - <filename>_input.tv: Hexadecimal input bytes.
        - <filename>_expected.tv: Hexadecimal output bytes (Golden Reference).
================================================================================
"""

import os

# Standard AES S-box used for keystream generation
AES_SBOX = [
    0x63, 0x7c, 0x77, 0x7b, 0xf2, 0x6b, 0x6f, 0xc5, 0x30, 0x01, 0x67, 0x2b, 0xfe, 0xd7, 0xab, 0x76,
    0xca, 0x82, 0xc9, 0x7d, 0xfa, 0x59, 0x47, 0xf0, 0xad, 0xd4, 0xa2, 0xaf, 0x9c, 0xa4, 0x72, 0xc0,
    0xb7, 0xfd, 0x93, 0x26, 0x36, 0x3f, 0xf7, 0xcc, 0x34, 0xa5, 0xe5, 0xf1, 0x71, 0xd8, 0x31, 0x15,
    0x04, 0xc7, 0x23, 0xc3, 0x18, 0x96, 0x05, 0x9a, 0x07, 0x12, 0x80, 0xe2, 0xeb, 0x27, 0xb2, 0x75,
    0x09, 0x83, 0x2c, 0x1a, 0x1b, 0x6e, 0x5a, 0xa0, 0x52, 0x3b, 0xd6, 0xb3, 0x29, 0xe3, 0x2f, 0x84,
    0x53, 0xd1, 0x00, 0xed, 0x20, 0xfc, 0xb1, 0x5b, 0x6a, 0xcb, 0xbe, 0x39, 0x4a, 0x4c, 0x58, 0xcf,
    0xd0, 0xef, 0xaa, 0xfb, 0x43, 0x4d, 0x33, 0x85, 0x45, 0x19, 0x02, 0x7f, 0x50, 0x3c, 0x9f, 0xa8,
    0x51, 0xa3, 0x40, 0x8f, 0x92, 0x9d, 0x38, 0xf5, 0xbc, 0xb6, 0xda, 0x21, 0x10, 0xff, 0xf3, 0xd2,
    0xcd, 0x0c, 0x13, 0xec, 0x5f, 0x97, 0x44, 0x17, 0xc4, 0xa7, 0x7e, 0x3d, 0x64, 0x5d, 0x19, 0x73,
    0x60, 0x81, 0x4f, 0xdc, 0x22, 0x2a, 0x90, 0x88, 0x46, 0xee, 0xb8, 0x14, 0xde, 0x5e, 0x0b, 0xdb,
    0xe0, 0x32, 0x3a, 0x0a, 0x49, 0x06, 0x24, 0x5c, 0xc2, 0xd3, 0xac, 0x62, 0x91, 0x95, 0xe4, 0x79,
    0xe7, 0xc8, 0x37, 0x6d, 0x8d, 0xd5, 0x4e, 0xa9, 0x6c, 0x56, 0xf4, 0xea, 0x65, 0x7a, 0xae, 0x08,
    0xba, 0x78, 0x25, 0x2e, 0x1c, 0xa6, 0xb4, 0xc6, 0xe8, 0xdd, 0x74, 0x1f, 0x4b, 0xbd, 0x8b, 0x8a,
    0x70, 0x3e, 0xb5, 0x66, 0x48, 0x03, 0xf6, 0x0e, 0x61, 0x35, 0x57, 0xb9, 0x86, 0xc1, 0x1d, 0x9e,
    0xe1, 0xf8, 0x98, 0x11, 0x69, 0xd9, 0x8e, 0x94, 0x9b, 0x1e, 0x87, 0xe9, 0xce, 0x55, 0x28, 0xdf,
    0x8c, 0xa1, 0x89, 0x0d, 0xbf, 0xe6, 0x42, 0x68, 0x41, 0x99, 0x2d, 0x0f, 0xb0, 0x54, 0xbb, 0x16
]

def process_message(data, key):
    """
    Core encryption/decryption logic.
    Each byte of data is XORed with a byte from the S-box.
    The S-box index is calculated as (Initial Key + current byte index) mod 256.
    """
    processed_data = []
    for i in range(len(data)):
        # Calculate the S-box index (circular buffer logic)
        sbox_index = (key + i) % 256
        # Retrieve the pseudo-random byte from the S-box
        keystream_byte = AES_SBOX[sbox_index]
        # XOR the data byte with the keystream byte
        out_byte = data[i] ^ keystream_byte
        processed_data.append(out_byte)
    return processed_data

def run_interactive_model():
    print("\n" + "="*50)
    print("       Stream_Cipher_V1: Golden Model      ")
    print("="*50)
    print("This tool generates Test Vector (.tv) files for hardware verification.")
    print("Note: The same process is used for ENCRYPTION and DECRYPTION.\n")

    # --- 1. Select Input Mode ---
    print("Select input format:")
    print("1) Encryption: ASCII Text (e.g., Hello World)")
    print("2) Decryption: Hexadecimal Bytes (e.g., 48 65 6c 6c 6f)")
    
    while True:
        choice = input("Selection (1 or 2): ").strip()
        if choice in ["1", "2"]:
            break
        print("Error: Invalid selection. Please enter 1 or 2.")

    if choice == "1":
        # Text Mode: Convert each character to its ASCII integer value
        msg_str = input("\nEnter the string to encrypt/decrypt: ")
        data_bytes = [ord(c) for c in msg_str]
    else:
        # Hex Mode: Convert space-separated hex strings to integers
        while True:
            try:
                hex_str = input("\nEnter hex bytes separated by spaces (e.g., 1a 2b ff 00): ")
                data_bytes = [int(x, 16) for x in hex_str.split()]
                break
            except ValueError:
                print("Error: Invalid hexadecimal format. Use only 0-9 and a-f.")

    # --- 2. Key Input with Validation ---
    while True:
        try:
            key_input = input("Enter the 8-bit Secret Key K (integer 0-255): ")
            key = int(key_input)
            if 0 <= key <= 255:
                break
            else:
                print("Error: The key must be between 0 and 255.")
        except ValueError:
            print("Error: Please enter a valid integer.")

    # --- 3. Output File Configuration ---
    # Define the output directory path here
    folder = "modelsim/tv"

    base_filename = input("Enter the base name for .tv files (default: test1): ").strip()
    if not base_filename:
        base_filename = "test1"

    # Ensure the directory exists; if it already exists, it does nothing
    if not os.path.exists(folder):
        os.makedirs(folder)
        print(f"[*] Directory created: {folder}")
    else:
        print(f"[*] Using existing directory: {folder}")

    # --- 4. Processing ---
    print(f"[*] Processing {len(data_bytes)} bytes with Key K=0x{key:02x}...")
    result_bytes = process_message(data_bytes, key)

    # --- 5. Write Test Vector Files ---
    input_path = f"{folder}/{base_filename}_input.tv"
    expected_path = f"{folder}/{base_filename}_expected.tv"

    # Write input bytes (one per line, hex format)
    # The 'w' mode will overwrite the files if they already exist
    try:
        with open(input_path, "w") as f:
            for b in data_bytes:
                f.write(f"{b:02x}\n")
                
        # Write result bytes (Golden Model reference)
        with open(expected_path, "w") as f:
            for b in result_bytes:
                f.write(f"{b:02x}\n")
                
        print(f"[*] Test vector files successfully written to {folder}")
    except IOError as e:
        print(f"Error: Could not write files. {e}")

    # --- 6. Results Summary ---
    print("\n" + "-"*40)
    print("PROCESSING SUMMARY")
    print("-"*40)
    print(f"Input  (Hex): {' '.join(f'{b:02x}' for b in data_bytes)}")
    print(f"Output (Hex): {' '.join(f'{b:02x}' for b in result_bytes)}")
    
    # Attempt to show ASCII representation of the output for printable characters
    try:
        text_preview = "".join(chr(b) if 32 <= b <= 126 else '?' for b in result_bytes)
        print(f"Text Preview: {text_preview}")
    except Exception:
        pass
    
    print("\n[SUCCESS] Files generated successfully:")
    print(f" -> {input_path}")
    print(f" -> {expected_path}")
    print("-"*40 + "\n")
    
if __name__ == "__main__":
    run_interactive_model()