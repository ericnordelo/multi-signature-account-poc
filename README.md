# Multiple signature validation mechanisms in Account

While implementing separate components (or contracts) to offer different signature validation mechanisms is not a big issue,
combining these solutions into a single component is an interesting extensibility problem. In this repository we can find three different implementation examples/suggestions on how to address this issue.

## Version 1

This first version leverages generic impls as params in functions to allow making the component agnostic of the signature
validation implementation.

Pros:
- AccountComponent doesn't grow if new signature validation mechanisms are added.
- We can keep the different validations mechanisms under one speficic component (SignatureValidator in this case).
- We can convert a StarknetAccount preset into an EthereumAccount one (and vice versa) by just changing one line.

Cons:
- We can't embbed directly functions depending on the generic ones, so we need to "re-expose" the functions involving this
manually in the presets.

NOTE: In the presets, note that the generic functions get the available implementation automatically, as expected.
This solution is similar to what we try to accomplish in version 2, but the latter doesn't compile, because we
try to use generic functions in external methods (receiving a generic implementation, not a type).

## Version 2

This second version doesn't compile, but it would be a nice feature if it were possible in my opinion. Notice that
the only difference with version 1, is that the embeddable implementations should allow generic impl functions, and this
could be concretized in the preset by making a compatible implementation available, similar to what happen in version 1.

Pros:
- AccountComponent doesn't grow if new signature validation mechanisms are added.
- We can keep the different validations mechanisms under one speficic component (SignatureValidator in this case).
- We can convert a StarknetAccount preset into an EthereumAccount one (and vice versa) by just changing one line.
- We don't need to re-expose functions in the preset.

Cons:
- It doesn't compile :).
- Adds some extra complexity, because is not clear that the implementation in context is being used inside the component.

## Version 3

This last version doesn't use generic impls, and instead simply adds a new implementation to the component itself.

Pros:
- Simple to implement
- We can convert a StarknetAccount preset into an EthereumAccount one (and vice versa) by just changing one line.
- We don't need to re-expose functions in the preset.

Cons:
- The component grows bigger with new validation mechanisms, having to duplicate all the methods belonging to the interface
even when only one of them is significant for validation.