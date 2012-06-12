

############################
class SerimiAligner < XAligner
  
# def alignment_algorithm(instances)
     # sourcedata =[]
     # targetdata =[]
      # tmp2=[]
      # limit = instances.size * $learning
      # entitylabels = source_entity_labels(instances[0..limit]).uniq 
#     
      # instances[0..limit].each {|s| 
#       
        # tmp =  Query.new.adapters($session[:origin]).sparql("select ?p ?o where {  #{s.to_s} ?p ?o }").execute
        # tmp.each {|p,o| sourcedata << [s,p,o] }        
        # entitylabels.each{|pre|
        # t = TransitionQuery.new(AttributeQuery.new(AttributeAlignment.new(pre,"?p"),0.6,QueryType::BIF),nil) 
        # tmp2 = tmp2 + t.query(s).elements.compact
#         
        # count = count - 1 if tmp2.map{|s,p,o| s}.uniq.size > 1
#         
        # targetdata = targetdata + tmp2  
         # }
      # }
#        
      # targetdata.uniq!  
      # puts " TARGET SIZE " + targetdata.size.to_s 
#     
      # entitylabels.map!{|x,y| x.to_s}
      # puts "BEFORE ALIGNMENT SOURCE ENTITY LABELS "
      # puts entitylabels
      # puts "#####################################"
      # alignments = assingment(sourcedata,targetdata)
      # puts "ALIGNMENT "
      # puts alignments
      # alignments.delete_if{|x| !entitylabels.include?(x.source)}
      # alignments.delete_if{|x| x.target == ""}
      # alignments
# end

def assingment(a,b)
  solver = Hungarian.new
  data= build_matrix(a,b)
  solution = solver.solve(data[2])
  solution = solution.map{|x| AttributeAlignment.new(data[0][x[0]].to_s, data[1][x[1]].to_s) }
  puts "SORUCE PREDICATES"
  puts data[0]
  puts "TARGET PREDICATES"
  puts data[1]
  return solution
end

def build_matrix(a, b)
  a= preparedata(a)
  b= preparedata(b)
   # m = syntax(a,b) #+  semantic(pt,ps) + value(pt,ps) + entropy(pt,ps)
  m =   entropy_based(a,b) 
  m2 =  syntax(a,b)
  
  
   m[2] = sum_arrays_normalizing(m[2],m2[2])
  
  return m
   
end

 # puts "x".get_similarity("xaaa","xaaa","LEVENSHTEIN")
end
