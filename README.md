# Transactions to Graph

<b>Update 4/5/2017: I presented a paper with this Macro in SAS Global Forum 2017 https://support.sas.com/resources/papers/proceedings17/1065-2017.pdf</b>

So SAS has finally had some fun toys to work with graphs! Yes, they are developing a PROC OPTGRAPH, and I am lucky enough to get to use one of its initial versions. Transforming transactional data to graphs in SAS is not too simple at the moment, so I am writing this Macro to assist you with that.

## The BUILD_GRAPH SAS Macro

Usages:

```
%BUILD_GRAPH(
    data = <data source>,
    link_object = <link object>,
    item = <vertex object>,
    filter = <additional filters on the data>,
    prob_graph = <No/Yes>
    );
```    

### Parameters
- <b>data</b>: the data set to build the graphs
- <b>link_object</b>: the link object used to compute the co-occurrence of two vertices. The co-occurrence is the number of times the two vertices have the same values of the link-object in the data. E.g. if an item co-occurrence graph from transactional data is desired, order is the link-object. If a customer graph is desired, link-object is the variable that carries item information.
- <b>item</b>: the object of interest to the graph. 
- <b>filter</b>: any desired filter to apply on the data. Have the same syntax as the SAS WHERE statement
- <b>prob_graph</b>: indicates if the probability graph should also be generated. Default value is NO (the yes/no values are not case-sensitive).

### The Macro’s Output
The macro handles all data transformation and output the co-occurrence graph data format:

```
{v_1,v_2,weight}
```

With each observation being an edge in the graph, v_1 and v_2 are the two ends of the edge, and weight is the co-occurrence of the object pair. The output co-occurrence graph data set is named CO_OCC_GRAPH.

If the prob_graph option is set to yes, the probability graph is also generated in the format

```
{v_1,v_2,co_occ,v_1_occ,weight }
```

Each observation in the data represent a directed edge, and the weight is the conditional probability of v_2 given v_1. The co_occ and v_1_occ attributes are preserved to accommodate further filters if needed. The output probability graph is named PROB_GRAPH.

All the temporary data sets generated during transformation are cleared after the macro finishes executing.

