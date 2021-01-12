class LineParser {

    LineParser()
    {
        # throw "This class is not meant to be instantiated directly."
    }

    ParseLine([object] $Line)
    {
        throw "this method must be overriden by the Parser implementation."
    }
}
