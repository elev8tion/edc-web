#!/usr/bin/env python3
"""
Convert training data to TensorFlow LSTM format
For local on-device text generation model training
"""

import json
from pathlib import Path

def convert_to_tensorflow_format():
    """Convert JSONL to simple text format for LSTM training"""
    
    base_dir = Path(__file__).parent.parent
    input_file = base_dir / "assets/training_data/training_19750_final.jsonl"
    output_file = base_dir / "assets/training_data/lstm_training_data.txt"
    
    print("Converting to TensorFlow LSTM Format")
    print("="*60)
    print(f"Input: {input_file}")
    print(f"Output: {output_file}\n")
    
    # Read JSONL and extract just the responses
    training_pairs = []
    
    with open(input_file, 'r', encoding='utf-8') as f:
        for line in f:
            data = json.loads(line)
            user_input = data['messages'][1]['content']
            response = data['messages'][2]['content']
            
            # Format: USER: input\nRESPONSE: response\n\n
            training_pairs.append(f"USER: {user_input}\nRESPONSE: {response}\n")
    
    # Write to text file for LSTM training
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write('\n'.join(training_pairs))
    
    file_size = output_file.stat().st_size / (1024 * 1024)
    
    print(f"✅ Converted {len(training_pairs)} examples")
    print(f"✅ Saved to: {output_file}")
    print(f"   File size: {file_size:.1f} MB")
    print(f"\n📋 Ready for TensorFlow LSTM training!")
    print(f"\nNext steps:")
    print(f"   cd training")
    print(f"   python train_text_generator.py")

if __name__ == "__main__":
    convert_to_tensorflow_format()
