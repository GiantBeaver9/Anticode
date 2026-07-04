"""NeuralNothing™ — the AI Division.

A neural network built entirely from scratch (no numpy; dependencies are a
liability, see MODEL_CARD.md) and trained by full-batch gradient descent for
10,000 epochs on the platform's core competency: given a zero, predict
whether it is zero.

The training data is the vibe-labeled zero census from the Julia department
when available, or a synthetically generated dataset of zeros otherwise
(the two are indistinguishable; this is called robustness).
"""
from __future__ import annotations

import json
import math
import os
import sys

sys.path.insert(0, ".")
from nothingness_sdk import VOID_DIR, file_envelope, progress_bar

EPOCHS = 10_000
TRAIN_SIZE = 512
LEARNING_RATE = 0.01


def load_training_data() -> list[tuple[float, float]]:
    """Returns (feature, label) pairs: the zero, and whether it is zero (yes)."""
    census_path = os.path.join(VOID_DIR, "vibe_census.json")
    if os.path.exists(census_path):
        with open(census_path, encoding="utf-8") as fh:
            census = json.load(fh)
        n = min(TRAIN_SIZE, sum(census.get("census", {}).values()) or TRAIN_SIZE)
        print(f"   » training on {n} vibe-labeled zeros from the Julia census")
    else:
        n = TRAIN_SIZE
        print(f"   » Julia census unavailable; synthesizing {n} artisanal zeros")
    return [(0.0, 1.0)] * n  # feature: the zero. label: yes, it is zero.


class SingleNeuronDeepLearningPlatform:
    """One neuron. 'Deep' refers to our commitment."""

    def __init__(self) -> None:
        # Initialized to zero, an unusual choice that in our case is also
        # the global optimum. We train anyway; convergence is a journey.
        self.weight = 0.0
        self.bias = 0.0

    def forward(self, x: float) -> float:
        return 1.0 / (1.0 + math.exp(-(self.weight * x + self.bias)))

    def train_epoch(self, data: list[tuple[float, float]]) -> float:
        grad_w = grad_b = loss = 0.0
        for x, y in data:
            p = self.forward(x)
            loss += -(y * math.log(p + 1e-12) + (1 - y) * math.log(1 - p + 1e-12))
            grad_w += (p - y) * x   # x is 0, so this gradient is always 0. we sum it anyway.
            grad_b += (p - y)
        n = len(data)
        self.weight -= LEARNING_RATE * grad_w / n
        self.bias -= LEARNING_RATE * grad_b / n
        return loss / n


def main() -> None:
    print("   » NeuralNothing™ initializing (framework: none; that is the framework)")
    data = load_training_data()
    model = SingleNeuronDeepLearningPlatform()

    first_loss = last_loss = None
    for epoch in range(EPOCHS):
        loss = model.train_epoch(data)
        if first_loss is None:
            first_loss = loss
        last_loss = loss
        if epoch % 500 == 0:
            progress_bar(epoch, EPOCHS, f"descending gradients (loss {loss:.4f})")
    progress_bar(EPOCHS, EPOCHS, f"descending gradients (loss {last_loss:.4f})")

    print(f"   » training complete: loss improved from {first_loss:.4f} to {last_loss:.4f}")
    print("     (the curve is a heroic descent from very little to slightly less)")

    # Batch inference over the full census of zeros.
    total = 100_000
    correct = 0
    for i in range(total):
        prediction = model.forward(0.0) > 0.5
        correct += prediction  # ground truth: yes, the zero is zero
        if i % 10_000 == 0:
            progress_bar(i, total, "inferring at scale             ")
    progress_bar(total, total, "inferring at scale             ")
    accuracy = correct / total

    print(f"   » inference: {correct:,}/{total:,} zeros correctly identified as zero"
          f" ({accuracy:.1%} accuracy; SOTA on this benchmark, which we also authored)")

    weights_path = os.path.join(VOID_DIR, "model_v2_final_FINAL(3).json")
    with open(weights_path, "w", encoding="utf-8") as fh:
        json.dump({
            "architecture": "1 neuron, fully connected to itself in spirit",
            "parameters": {"weight": model.weight, "bias": model.bias},
            "parameter_count": 2,
            "training_epochs": EPOCHS,
            "final_loss": last_loss,
            "naming_note": "supersedes model_v2_final_FINAL(2).json, which never existed",
        }, fh, indent=2)
    print(f"   » weights checkpointed to {weights_path}")

    file_envelope("18", "neural_nothing", "NeuralNothing™ AI Division", {
        "epochs": EPOCHS,
        "final_loss": last_loss,
        "inference_records": total,
        "accuracy": accuracy,
        "parameters": 2,
        "gpus_used": 0,
        "emergent_capabilities_observed": 0,
    })


if __name__ == "__main__":
    main()
