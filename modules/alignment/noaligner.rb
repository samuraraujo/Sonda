##########################
class NoAligner
  include Serimi_Module
    
def alignment_algorithm(instances)
     limit = instances.size * $learning
     entitylabels = source_entity_labels(instances[0..limit]).uniq
     entitylabels.map{|a| AttributeAlignment.new(a,"?p")}
end
end
#########