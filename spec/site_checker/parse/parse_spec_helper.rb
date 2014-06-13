module ParseSpecHelper
  def assert_link(link, kind, location, has_problem, problem=nil)
		expect(link.kind).to eql(kind)
		expect(link.location).to eql(location)
		expect(link.has_problem?).to eql(has_problem)
		expect(link.problem).to eql(problem) if problem
	end
end