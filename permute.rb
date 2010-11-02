class String
  def permute(delim="_")
    elements = self.split(delim)
    combinations=[]
    elements.each_with_index do |element,i|
      # the by-itself combination
      combinations<<[element]
      # the last item's combinations are already defined
      unless i==elements.size-1
        elements[(i+1)..(elements.size-1)].each do |next_element|
          combinations<<(combinations.last.dup<<next_element)
        end
      end
      break
    end

    combinations.collect {|c| c.join(delim)}
  end
end
