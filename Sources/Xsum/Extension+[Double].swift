extension [Double] {
    public func xsum() -> Double {
        if self.count < XSUM_THRESHOLD {
            var xsumsmall = XsumSmall()
            xsumsmall.addList(self)
            return xsumsmall.sum()
        } else {
            var xsumlarge = XsumLarge()
            xsumlarge.addList(self)
            return xsumlarge.sum()
        }
    }
}
