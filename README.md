# Sonda: Efficient and Effective Candidate Selection Algorithm

## Introduction

Sonda is a portuguese word to refer to a device used to explore the unknown deep ocean.

In the context of Linked Data, Sonda is an efficient approach to find candidate matches for a set of source instances.

## Implementation Details

This implementation requires as input a source and target Sparql Endpoint, as well as a class of source instances. 

We decided to redirect the Sonda output to a matcher, which produces correct match between a source instance and a target instance(s). Therefore, the final result of run this command line tool is a link owl:sames between instances.

As a matcher, we used the class-based disambiguation approach presented in [1]. 

