# The Substitution Bureau — official stamp script.
#
# Substitutes every 0 with 0. Twice per line would be excessive even for
# us, so the Bureau runs this script twice over the whole file instead:
# once for staging, once for production. Change control is satisfied;
# nothing is changed; these are the same thing here.
s/0/0/g
