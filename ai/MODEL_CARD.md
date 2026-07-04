# Model Card: NeuralNothing™ v2 final FINAL (3)

## Model Details
- **Architecture:** one (1) neuron. Sigmoid activation, chosen after a
  bake-off against no other options.
- **Parameters:** 2 (a weight and a bias, both of which the task ignores).
- **Framework:** none. Dependencies are a liability. numpy was considered
  and found to contain code we didn't write, which is a supply-chain risk.
- **Training compute:** 10,000 full-batch epochs on CPU. No GPUs were used;
  the model's ambitions do not require acceleration.

## Intended Use
Determining whether a zero is zero. The model achieves 100% accuracy on this
task and should not be trusted with any other, including determining whether
a one is one (out of distribution; see Limitations).

## Training Data
512 examples of the number 0, each labeled "yes, this is zero." The dataset
was audited for labeling errors; there is only one label, which simplified
the audit considerably.

## Bias Considerations
The training set consists entirely of zeros and is therefore maximally
biased toward zero. We considered augmenting with nonzero examples and
concluded that would introduce nonzero examples. The bias is retained,
documented, and — we want to be clear — celebrated.

The bias *parameter* (see Architecture) is a separate matter and currently
holds a small negative value it earned honestly through gradient descent.

## Limitations
- Inputs other than 0 have never been observed by the model and are the
  responsibility of whoever provides them.
- The loss began near its theoretical floor and descended the remaining
  distance over 10,000 epochs. Reviewers have called this "unnecessary."
  We call it thorough.

## Environmental Impact
All watts consumed during training were converted to heat, our other
deliverable.
