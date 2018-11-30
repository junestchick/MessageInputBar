/*
 MIT License
 
 Copyright (c) 2017-2018 MessageKit
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 */

import UIKit

/// A powerful InputAccessoryView ideal for messaging applications
open class MessageInputBar: UIView {
    
    // MARK: - Properties
    
    /// A delegate to broadcast notifications from the `MessageInputBar`
    open weak var delegate: MessageInputBarDelegate?
    /// Font used id input bar
    open var font: UIFont?
    /// The background UIView anchored to the bottom, left, and right of the MessageInputBar
    /// with a top anchor equal to the bottom of the top InputStackView
    open var backgroundView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor(red: 247/255, green: 247/255, blue: 247/255, alpha: 1.0)
        return view
    }()
    
    /// A content UIView that holds the left/right/bottom InputStackViews and InputTextView. Anchored to the bottom of the
    /// topStackView and inset by the padding UIEdgeInsets
    open var contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    /**
     A UIVisualEffectView that adds a blur effect to make the view appear transparent.
     
     ## Important Notes ##
     1. The blurView is initially not added to the backgroundView to improve performance when not needed. When `isTranslucent` is set to TRUE for the first time the blurView is added and anchored to the `backgroundView`s edge anchors
     */
    open var blurView: UIVisualEffectView = {
        let blurEffect = UIBlurEffect(style: .light)
        let view = UIVisualEffectView(effect: blurEffect)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    /// Determines if the MessageInputBar should have a translucent effect
    open var isTranslucent: Bool = false {
        didSet {
            if isTranslucent && blurView.superview == nil {
                backgroundView.addSubview(blurView)
                blurView.fillSuperview()
            }
            blurView.isHidden = !isTranslucent
            let color: UIColor = backgroundView.backgroundColor ?? UIColor(red: 247/255, green: 247/255, blue: 247/255, alpha: 1.0)
            backgroundView.backgroundColor = isTranslucent ? color.withAlphaComponent(0.75) : color.withAlphaComponent(1.0)
        }
    }
    
    /// A SeparatorLine that is anchored at the top of the MessageInputBar with a height of 1
    public let separatorLine = SeparatorLine()
    
    public var topView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private var swipeView = UIView()
    
    public var topCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 5
        layout.minimumLineSpacing = 0
        layout.scrollDirection = .vertical
        let collectionV = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionV.backgroundColor = .white
        collectionV.register(TextCollectionCell.self, forCellWithReuseIdentifier: "cel")
        collectionV.translatesAutoresizingMaskIntoConstraints = false
        collectionV.backgroundColor = .clear
        return collectionV
    }()
    
    private var noResultLabel: UILabel = {
        let label = UILabel()
        label.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        label.text = "No result"
        label.textAlignment = .center
        label.textColor = .lightGray
        return label
    }()
    
    /**
     The InputStackView at the InputStackView.top position
     
     ## Important Notes ##
     1. It's axis is initially set to .vertical
     2. It's alignment is initially set to .fill
     */
    //    public let topStackView: InputStackView = {
    //        let stackView = InputStackView(axis: .vertical, spacing: 0)
    //        stackView.alignment = .fill
    //        return stackView
    //    }()
    
    /**
     The InputStackView at the InputStackView.left position
     
     ## Important Notes ##
     1. It's axis is initially set to .horizontal
     */
    public let leftStackView = InputStackView(axis: .horizontal, spacing: 0)
    
    /**
     The InputStackView at the InputStackView.right position
     
     ## Important Notes ##
     1. It's axis is initially set to .horizontal
     */
    public let rightStackView = InputStackView(axis: .horizontal, spacing: 0)
    
    /**
     The InputStackView at the InputStackView.bottom position
     
     ## Important Notes ##
     1. It's axis is initially set to .horizontal
     2. It's spacing is initially set to 15
     */
    public let bottomStackView = InputStackView(axis: .horizontal, spacing: 15)
    
    /// The InputTextView a user can input a message in
    open lazy var inputTextView: InputTextView = { [weak self] in
        let inputTextView = InputTextView()
        inputTextView.translatesAutoresizingMaskIntoConstraints = false
        inputTextView.messageInputBar = self
        return inputTextView
        }()
    
    /// A InputBarButtonItem used as the send button and initially placed in the rightStackView
    open var sendButton: InputBarButtonItem = {
        return InputBarButtonItem()
            .configure {
                $0.setSize(CGSize(width: 52, height: 36), animated: false)
                $0.isEnabled = false
                $0.title = "Send"
                $0.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .bold)
            }.onTouchUpInside {
                $0.messageInputBar?.didSelectSendButton()
        }
    }()
    
    /**
     The anchor contants used by the InputStackView's and InputTextView to create padding
     within the MessageInputBar
     
     ## Important Notes ##
     
     ````
     V:|...[InputStackView.top]-(padding.top)-[contentView]-(padding.bottom)-|
     
     H:|-(padding.left)-[contentView]-(padding.right)-|
     ````
     
     */
    open var padding: UIEdgeInsets = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12) {
        didSet {
            updatePadding()
        }
    }
    
    /**
     The anchor constants used by the top InputStackView
     
     ## Important Notes ##
     1. The topStackViewPadding.bottom property is not used. Use padding.top
     
     ````
     V:|-(topStackViewPadding.top)-[InputStackView.top]-(padding.top)-[InputTextView]-...|
     
     H:|-(topStackViewPadding.left)-[InputStackView.top]-(topStackViewPadding.right)-|
     ````
     
     */
    open var topStackViewPadding: UIEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0) {
        didSet {
            updateTopStackViewPadding()
        }
    }
    
    /**
     The anchor constants used by the InputStackView
     
     ````
     V:|...-(padding.top)-(textViewPadding.top)-[InputTextView]-(textViewPadding.bottom)-[InputStackView.bottom]-...|
     
     H:|...-[InputStackView.left]-(textViewPadding.left)-[InputTextView]-(textViewPadding.right)-[InputStackView.right]-...|
     ````
     
     */
    open var textViewPadding: UIEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 8) {
        didSet {
            updateTextViewPadding()
        }
    }
    
    /// Returns the most recent size calculated by `calculateIntrinsicContentSize()`
    open override var intrinsicContentSize: CGSize {
        return cachedIntrinsicContentSize
    }
    
    /// The intrinsicContentSize can change a lot so the delegate method
    /// `inputBar(self, didChangeIntrinsicContentTo: size)` only needs to be called
    /// when it's different
    public private(set) var previousIntrinsicContentSize: CGSize?
    
    /// The most recent calculation of the intrinsicContentSize
    private lazy var cachedIntrinsicContentSize: CGSize = calculateIntrinsicContentSize()
    
    /// A boolean that indicates if the maxTextViewHeight has been met. Keeping track of this
    /// improves the performance
    public private(set) var isOverMaxTextViewHeight = false
    
    /// A boolean that when set as `TRUE` will always enable the `InputTextView` to be anchored to the
    /// height of `maxTextViewHeight`
    /// The default value is `FALSE`
    public private(set) var shouldForceTextViewMaxHeight = false
    
    /// A boolean that determines if the `maxTextViewHeight` should be maintained automatically.
    /// To control the maximum height of the view yourself, set this to `false`.
    open var shouldAutoUpdateMaxTextViewHeight = true
    
    /// The maximum height that the InputTextView can reach.
    /// This is set automatically when `shouldAutoUpdateMaxTextViewHeight` is true.
    /// To control the height yourself, make sure to set `shouldAutoUpdateMaxTextViewHeight` to false.
    open var maxTextViewHeight: CGFloat = 0 {
        didSet {
            textViewHeightAnchor?.constant = maxTextViewHeight
            invalidateIntrinsicContentSize()
        }
    }
    
    /// A boolean that determines whether the sendButton's `isEnabled` state should be managed automatically.
    open var shouldManageSendButtonEnabledState = true
    
    /// The height that will fit the current text in the InputTextView based on its current bounds
    public var requiredInputTextViewHeight: CGFloat {
        let maxTextViewSize = CGSize(width: inputTextView.bounds.width, height: .greatestFiniteMagnitude)
        return inputTextView.sizeThatFits(maxTextViewSize).height.rounded(.down)
    }
    
    /// The fixed widthAnchor constant of the leftStackView
    public private(set) var leftStackViewWidthConstant: CGFloat = 0 {
        didSet {
            leftStackViewLayoutSet?.width?.constant = leftStackViewWidthConstant
        }
    }
    
    /// The fixed widthAnchor constant of the rightStackView
    public private(set) var rightStackViewWidthConstant: CGFloat = 52 {
        didSet {
            rightStackViewLayoutSet?.width?.constant = rightStackViewWidthConstant
        }
    }
    
    /// Holds the InputPlugin plugins that can be used to extend the functionality of the MessageInputBar
    open var plugins = [InputPlugin]()
    
    /// The InputBarItems held in the leftStackView
    public private(set) var leftStackViewItems: [InputItem] = []
    
    /// The InputBarItems held in the rightStackView
    public private(set) var rightStackViewItems: [InputItem] = []
    
    /// The InputBarItems held in the bottomStackView
    public private(set) var bottomStackViewItems: [InputItem] = []
    
    /// The InputBarItems held in the topStackView
    public private(set) var topStackViewItems: [InputItem] = []
    
    /// The InputBarItems held to make use of their hooks but they are not automatically added to a UIStackView
    open var nonStackViewItems: [InputItem] = []
    
    /// Returns a flatMap of all the items in each of the UIStackViews
    public var items: [InputItem] {
        return [leftStackViewItems, rightStackViewItems, bottomStackViewItems, topStackViewItems, nonStackViewItems].flatMap { $0 }
    }
    
    // MARK: - Auto-Layout Constraint Sets
    
    private var textViewLayoutSet: NSLayoutConstraintSet?
    private var textViewHeightAnchor: NSLayoutConstraint?
    private var topViewLayoutSet: NSLayoutConstraintSet?
    private var topViewHeightContraint: NSLayoutConstraint?
    private var leftStackViewLayoutSet: NSLayoutConstraintSet?
    private var rightStackViewLayoutSet: NSLayoutConstraintSet?
    private var bottomStackViewLayoutSet: NSLayoutConstraintSet?
    private var contentViewLayoutSet: NSLayoutConstraintSet?
    private var windowAnchor: NSLayoutConstraint?
    private var backgroundViewBottomAnchor: NSLayoutConstraint?
    
    // MARK: - Initialization
    
    public convenience init() {
        self.init(frame: .zero)
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    open override func didMoveToWindow() {
        super.didMoveToWindow()
        setupConstraints(to: window)
    }
    
    // MARK: - Setup
    
    /// Sets up the default properties
    open func setup() {
        
        autoresizingMask = [.flexibleHeight]
        setupSubviews()
        setupConstraints()
        setupObservers()
    }
    
    /// Adds the required notification observers
    private func setupObservers() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(MessageInputBar.orientationDidChange),
                                               name: UIDevice.orientationDidChangeNotification, object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(MessageInputBar.inputTextViewDidChange),
                                               name: UITextView.textDidChangeNotification, object: inputTextView)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(MessageInputBar.inputTextViewDidBeginEditing),
                                               name: UITextView.textDidBeginEditingNotification, object: inputTextView)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(MessageInputBar.inputTextViewDidEndEditing),
                                               name: UITextView.textDidEndEditingNotification, object: inputTextView)
    }
    
    /// Adds all of the subviews
    private func setupSubviews() {
        if let font = self.font {
            inputTextView.font = font.withSize(14)
        }
        addSubview(backgroundView)
        addSubview(contentView)
        addSubview(separatorLine)
        setupTopView()
        contentView.addSubview(inputTextView)
        contentView.addSubview(leftStackView)
        contentView.addSubview(rightStackView)
        contentView.addSubview(bottomStackView)
        setStackViewItems([sendButton], forStack: .right, animated: false)
    }
    
    private func setupTopView() {
        addSubview(topView)
        topView.addSubview(topCollectionView)
        topView.addSubview(swipeView)
        swipeView.translatesAutoresizingMaskIntoConstraints = false
        swipeView.layer.cornerRadius = 8
        swipeView.backgroundColor = .white
        let swipeUpGS = UISwipeGestureRecognizer(target: self, action: #selector(swipedUp))
        swipeUpGS.direction = .up
        swipeView.addGestureRecognizer(swipeUpGS)
        
        let swipeDownGS = UISwipeGestureRecognizer(target: self, action: #selector(swipedDown))
        swipeDownGS.direction = .down
        swipeView.addGestureRecognizer(swipeDownGS)
        //        swipeView.isUserInteractionEnabled = true
        
        topCollectionView.delegate = self
        topCollectionView.dataSource = self
        topView.clipsToBounds = true
        topView.bringSubviewToFront(topCollectionView)
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        addShadowForSwipeView()
        //        addShadowForSendButton()
    }
    
    private func addShadowForSwipeView() {
        swipeView.layer.masksToBounds = false
        swipeView.clipsToBounds = false
        swipeView.layer.shadowColor = UIColor.black.cgColor
        swipeView.layer.shadowOffset = CGSize(width: 0, height: -5)
        swipeView.layer.shadowRadius = 5
        swipeView.layer.shadowOpacity = 0.06
        swipeView.layer.shadowPath = UIBezierPath(rect: swipeView.bounds).cgPath
    }
    
    private func addShadowForSendButton() {
        sendButton.layer.masksToBounds = false
        sendButton.clipsToBounds = false
        sendButton.layer.shadowColor = UIColor.black.cgColor
        sendButton.layer.shadowOffset = CGSize(width: 0, height: 1)
        sendButton.layer.shadowRadius = 2
        sendButton.layer.shadowOpacity = 0.12
        sendButton.layer.shadowPath = UIBezierPath(rect: swipeView.bounds).cgPath
    }
    
    @objc private func swipedUp() {
        //        UIView.animate(withDuration: 0.4) {
        //            self.topViewHeightContraint?.isActive = true
        //            self.topViewHeightContraint?.constant = 400
        //            self.layoutIfNeeded()
        //        }
    }
    
    @objc private func swipedDown() {
        //        let dy = self.frame.origin.y - 44 - topView.frame.height
        //        print(dy)
        //        UIView.animate(withDuration: 0.0) {
        //            self.topViewHeightContraint?.isActive = true
        //            self.topViewHeightContraint?.constant = 185
        //            self.layoutIfNeeded()
        //        }
    }
    
    /// Sets up the initial constraints of each subview
    private func setupConstraints() {
        
        // The constraints within the MessageInputBar
        separatorLine.addConstraints(topAnchor, left: leftAnchor, right: rightAnchor, heightConstant: separatorLine.height)
        backgroundViewBottomAnchor = backgroundView.bottomAnchor.constraint(equalTo: bottomAnchor)
        backgroundViewBottomAnchor?.isActive = true
        backgroundView.addConstraints(topCollectionView.bottomAnchor, left: leftAnchor, right: rightAnchor)
        
        // Layout for collectionView and swipeView
        swipeView.topAnchor.constraint(equalTo: topView.topAnchor, constant: 10).isActive = true
        swipeView.widthAnchor.constraint(equalTo: topView.widthAnchor, constant: 0).isActive = true
        swipeView.bottomAnchor.constraint(equalTo: topCollectionView.topAnchor, constant: 25).isActive = true
        swipeView.centerXAnchor.constraint(equalTo: topView.centerXAnchor, constant: 0).isActive = true
        swipeView.heightAnchor.constraint(equalToConstant: 50).isActive = true
        let swipeImage = UIImageView()
        swipeImage.image = UIImage(named: "ic_swipe_bar")
        swipeImage.translatesAutoresizingMaskIntoConstraints = false
        swipeView.addSubview(swipeImage)
        swipeImage.heightAnchor.constraint(equalToConstant: 3).isActive = true
        swipeImage.widthAnchor.constraint(equalToConstant: 30).isActive = true
        swipeImage.centerXAnchor.constraint(equalTo: swipeView.centerXAnchor, constant: 0).isActive = true
        swipeImage.centerYAnchor.constraint(equalTo: swipeView.centerYAnchor, constant: -11).isActive = true
        topCollectionView.topAnchor.constraint(equalTo: swipeView.bottomAnchor, constant: -25).isActive = true
        topCollectionView.widthAnchor.constraint(equalTo: topView.widthAnchor, constant: 0).isActive = true
        topCollectionView.bottomAnchor.constraint(equalTo: topView.bottomAnchor, constant: 0).isActive = true
        topCollectionView.centerXAnchor.constraint(equalTo: topView.centerXAnchor, constant: 0).isActive = true
        
        
        topViewLayoutSet = NSLayoutConstraintSet(
            top:    topView.topAnchor.constraint(equalTo: topAnchor, constant: topStackViewPadding.top),
            bottom: topView.bottomAnchor.constraint(equalTo: contentView.topAnchor, constant: -padding.top),
            left:   topView.leftAnchor.constraint(equalTo: leftAnchor, constant: topStackViewPadding.left),
            right:  topView.rightAnchor.constraint(equalTo: rightAnchor, constant: -topStackViewPadding.right)
        )
        topViewHeightContraint = topView.heightAnchor.constraint(equalToConstant: 0)
        topViewHeightContraint?.isActive = true
        
        contentViewLayoutSet = NSLayoutConstraintSet(
            top:    contentView.topAnchor.constraint(equalTo: topView.bottomAnchor, constant: padding.top),
            bottom: contentView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -padding.bottom),
            left:   contentView.leftAnchor.constraint(equalTo: leftAnchor, constant: padding.left),
            right:  contentView.rightAnchor.constraint(equalTo: rightAnchor, constant: -padding.right)
        )
        
        if #available(iOS 11.0, *) {
            // Switch to safeAreaLayoutGuide
            contentViewLayoutSet?.bottom = contentView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -padding.bottom)
            contentViewLayoutSet?.left = contentView.leftAnchor.constraint(equalTo: safeAreaLayoutGuide.leftAnchor, constant: padding.left)
            contentViewLayoutSet?.right = contentView.rightAnchor.constraint(equalTo: safeAreaLayoutGuide.rightAnchor, constant: -padding.right)
            
            topViewLayoutSet?.left = topView.leftAnchor.constraint(equalTo: safeAreaLayoutGuide.leftAnchor, constant: topStackViewPadding.left)
            topViewLayoutSet?.right = topView.rightAnchor.constraint(equalTo: safeAreaLayoutGuide.rightAnchor, constant: -topStackViewPadding.right)
        }
        
        // Constraints Within the contentView
        textViewLayoutSet = NSLayoutConstraintSet(
            top:    inputTextView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: textViewPadding.top),
            bottom: inputTextView.bottomAnchor.constraint(equalTo: bottomStackView.topAnchor, constant: -textViewPadding.bottom),
            left:   inputTextView.leftAnchor.constraint(equalTo: leftStackView.rightAnchor, constant: textViewPadding.left),
            right:  inputTextView.rightAnchor.constraint(equalTo: rightStackView.leftAnchor, constant: -textViewPadding.right)
        )
        maxTextViewHeight = calculateMaxTextViewHeight()
        textViewHeightAnchor = inputTextView.heightAnchor.constraint(equalToConstant: maxTextViewHeight)
        
        leftStackViewLayoutSet = NSLayoutConstraintSet(
            top:    leftStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 0),
            bottom: leftStackView.bottomAnchor.constraint(equalTo: inputTextView.bottomAnchor, constant: 0),
            left:   leftStackView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 0),
            width:  leftStackView.widthAnchor.constraint(equalToConstant: leftStackViewWidthConstant)
        )
        
        rightStackViewLayoutSet = NSLayoutConstraintSet(
            top:    rightStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 0),
            bottom: rightStackView.bottomAnchor.constraint(equalTo: inputTextView.bottomAnchor, constant: 0),
            right:  rightStackView.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: 0),
            width:  rightStackView.widthAnchor.constraint(equalToConstant: rightStackViewWidthConstant)
        )
        
        bottomStackViewLayoutSet = NSLayoutConstraintSet(
            top:    bottomStackView.topAnchor.constraint(equalTo: inputTextView.bottomAnchor, constant: textViewPadding.bottom),
            bottom: bottomStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: 0),
            left:   bottomStackView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 0),
            right:  bottomStackView.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: 0)
        )
        activateConstraints()
    }
    
    /// Respect iPhone X safeAreaInsets
    /// Adds a constraint to anchor the bottomAnchor of the contentView to the window's safeAreaLayoutGuide.bottomAnchor
    ///
    /// - Parameter window: The window to anchor to
    private func setupConstraints(to window: UIWindow?) {
        if #available(iOS 11.0, *) {
            guard UIScreen.main.nativeBounds.height == 2436 else { return }
            if let window = window {
                windowAnchor?.isActive = false
                windowAnchor = contentView.bottomAnchor.constraint(lessThanOrEqualToSystemSpacingBelow: window.safeAreaLayoutGuide.bottomAnchor, multiplier: 1)
                windowAnchor?.constant = -padding.bottom
                windowAnchor?.priority = UILayoutPriority(rawValue: 750)
                windowAnchor?.isActive = true
                backgroundViewBottomAnchor?.constant = 34
            }
        }
    }
    
    // MARK: - Constraint Layout Updates
    
    /// Updates the constraint constants that correspond to the padding UIEdgeInsets
    private func updatePadding() {
        topViewLayoutSet?.bottom?.constant = -padding.top
        contentViewLayoutSet?.top?.constant = padding.top
        contentViewLayoutSet?.left?.constant = padding.left
        contentViewLayoutSet?.right?.constant = -padding.right
        contentViewLayoutSet?.bottom?.constant = -padding.bottom
        windowAnchor?.constant = -padding.bottom
    }
    
    /// Updates the constraint constants that correspond to the textViewPadding UIEdgeInsets
    private func updateTextViewPadding() {
        textViewLayoutSet?.top?.constant = textViewPadding.top
        textViewLayoutSet?.left?.constant = textViewPadding.left
        textViewLayoutSet?.right?.constant = -textViewPadding.right
        textViewLayoutSet?.bottom?.constant = -textViewPadding.bottom
        bottomStackViewLayoutSet?.top?.constant = textViewPadding.bottom
    }
    
    /// Updates the constraint constants that correspond to the topStackViewPadding UIEdgeInsets
    private func updateTopStackViewPadding() {
        topViewLayoutSet?.top?.constant = topStackViewPadding.top
        topViewLayoutSet?.left?.constant = topStackViewPadding.left
        topViewLayoutSet?.right?.constant = -topStackViewPadding.right
    }
    
    /// Invalidates the view’s intrinsic content size
    open override func invalidateIntrinsicContentSize() {
        super.invalidateIntrinsicContentSize()
        cachedIntrinsicContentSize = calculateIntrinsicContentSize()
        if previousIntrinsicContentSize != cachedIntrinsicContentSize {
            delegate?.messageInputBar(self, didChangeIntrinsicContentTo: cachedIntrinsicContentSize)
            previousIntrinsicContentSize = cachedIntrinsicContentSize
        }
    }
    
    /// Calculates the correct intrinsicContentSize of the MessageInputBar
    ///
    /// - Returns: The required intrinsicContentSize
    open func calculateIntrinsicContentSize() -> CGSize {
        
        var inputTextViewHeight = requiredInputTextViewHeight
        if inputTextViewHeight >= maxTextViewHeight {
            if !isOverMaxTextViewHeight {
                textViewHeightAnchor?.isActive = true
                inputTextView.isScrollEnabled = true
                isOverMaxTextViewHeight = true
                inputTextView.layoutIfNeeded()
            }
            inputTextViewHeight = maxTextViewHeight
        } else {
            if isOverMaxTextViewHeight {
                textViewHeightAnchor?.isActive = false || shouldForceTextViewMaxHeight
                inputTextView.isScrollEnabled = false
                isOverMaxTextViewHeight = false
                inputTextView.invalidateIntrinsicContentSize()
            }
        }
        
        // Calculate the required height
        let totalPadding = padding.top + padding.bottom + topStackViewPadding.top + textViewPadding.top + textViewPadding.bottom
        let topStackViewHeight = topCollectionView.numberOfItems(inSection: 0) > 0 ? topViewHeightContraint?.constant ?? 0 : 0
        let bottomStackViewHeight = bottomStackView.arrangedSubviews.count > 0 ? bottomStackView.bounds.height : 0
        let verticalStackViewHeight = topStackViewHeight + bottomStackViewHeight
        let requiredHeight = inputTextViewHeight + totalPadding + verticalStackViewHeight
        return CGSize(width: bounds.width, height: requiredHeight)
    }
    
    
    /// Returns the max height the InputTextView can grow to based on the UIScreen
    ///
    /// - Returns: Max Height
    open func calculateMaxTextViewHeight() -> CGFloat {
        if traitCollection.verticalSizeClass == .regular {
            return (UIScreen.main.bounds.height / 3).rounded(.down)
        }
        return (UIScreen.main.bounds.height / 5).rounded(.down)
    }
    
    // MARK: - Layout Helper Methods
    
    /// Layout the given InputStackView's
    ///
    /// - Parameter positions: The InputStackView's to layout
    public func layoutStackViews(_ positions: [InputStackView.Position] = [.left, .right, .bottom, .top]) {
        
        guard superview != nil else { return }
        for position in positions {
            switch position {
            case .left:
                leftStackView.setNeedsLayout()
                leftStackView.layoutIfNeeded()
            case .right:
                rightStackView.setNeedsLayout()
                rightStackView.layoutIfNeeded()
            case .bottom:
                bottomStackView.setNeedsLayout()
                bottomStackView.layoutIfNeeded()
            case .top:
                topView.setNeedsLayout()
                topView.layoutIfNeeded()
            }
        }
    }
    
    /// Performs layout changes over the main thread
    ///
    /// - Parameters:
    ///   - animated: If the layout should be animated
    ///   - animations: Animation logic
    internal func performLayout(_ animated: Bool, _ animations: @escaping () -> Void) {
        deactivateConstraints()
        if animated {
            DispatchQueue.main.async {
                UIView.animate(withDuration: 0.3, animations: animations)
            }
        } else {
            UIView.performWithoutAnimation { animations() }
        }
        activateConstraints()
    }
    
    /// Activates the NSLayoutConstraintSet's
    private func activateConstraints() {
        contentViewLayoutSet?.activate()
        textViewLayoutSet?.activate()
        leftStackViewLayoutSet?.activate()
        rightStackViewLayoutSet?.activate()
        bottomStackViewLayoutSet?.activate()
        topViewLayoutSet?.activate()
    }
    
    /// Deactivates the NSLayoutConstraintSet's
    private func deactivateConstraints() {
        contentViewLayoutSet?.deactivate()
        textViewLayoutSet?.deactivate()
        leftStackViewLayoutSet?.deactivate()
        rightStackViewLayoutSet?.deactivate()
        bottomStackViewLayoutSet?.deactivate()
        topViewLayoutSet?.deactivate()
    }
    
    /// Removes all of the arranged subviews from the InputStackView and adds the given items.
    /// Sets the messageInputBar property of the InputBarButtonItem
    ///
    /// - Parameters:
    ///   - items: New InputStackView arranged views
    ///   - position: The targeted InputStackView
    ///   - animated: If the layout should be animated
    open func setStackViewItems(_ items: [InputItem], forStack position: InputStackView.Position, animated: Bool) {
        
        func setNewItems() {
            switch position {
            case .left:
                leftStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
                leftStackViewItems = items
                leftStackViewItems.forEach {
                    $0.messageInputBar = self
                    $0.parentStackViewPosition = position
                    if let view = $0 as? UIView {
                        leftStackView.addArrangedSubview(view)
                    }
                }
                guard superview != nil else { return }
                leftStackView.layoutIfNeeded()
            case .right:
                rightStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
                rightStackViewItems = items
                rightStackView.layer.masksToBounds = false
                rightStackView.clipsToBounds = false
                rightStackViewItems.forEach {
                    $0.messageInputBar = self
                    $0.parentStackViewPosition = position
                    if let view = $0 as? UIView {
                        rightStackView.addArrangedSubview(view)
                    }
                }
                guard superview != nil else { return }
                rightStackView.layoutIfNeeded()
            case .bottom:
                bottomStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
                bottomStackViewItems = items
                bottomStackViewItems.forEach {
                    $0.messageInputBar = self
                    $0.parentStackViewPosition = position
                    if let view = $0 as? UIView {
                        bottomStackView.addArrangedSubview(view)
                    }
                }
                guard superview != nil else { return }
                bottomStackView.layoutIfNeeded()
            case .top: break
            }
            invalidateIntrinsicContentSize()
        }
        
        performLayout(animated) {
            setNewItems()
        }
    }
    
    /// Sets the leftStackViewWidthConstant
    ///
    /// - Parameters:
    ///   - newValue: New widthAnchor constant
    ///   - animated: If the layout should be animated
    open func setLeftStackViewWidthConstant(to newValue: CGFloat, animated: Bool) {
        performLayout(animated) {
            self.leftStackViewWidthConstant = newValue
            self.layoutStackViews([.left])
            guard self.superview?.superview != nil else { return }
            self.superview?.superview?.layoutIfNeeded()
        }
    }
    
    /// Sets the rightStackViewWidthConstant
    ///
    /// - Parameters:
    ///   - newValue: New widthAnchor constant
    ///   - animated: If the layout should be animated
    open func setRightStackViewWidthConstant(to newValue: CGFloat, animated: Bool) {
        performLayout(animated) {
            self.rightStackViewWidthConstant = newValue
            self.layoutStackViews([.right])
            guard self.superview?.superview != nil else { return }
            self.superview?.superview?.layoutIfNeeded()
        }
    }
    
    /// Sets the `shouldForceTextViewMaxHeight` property
    ///
    /// - Parameters:
    ///   - newValue: New boolean value
    ///   - animated: If the layout should be animated
    open func setShouldForceMaxTextViewHeight(to newValue: Bool, animated: Bool) {
        performLayout(animated) {
            self.shouldForceTextViewMaxHeight = newValue
            self.textViewHeightAnchor?.isActive = newValue
            guard self.superview?.superview != nil else { return }
            self.superview?.superview?.layoutIfNeeded()
        }
    }
    
    // MARK: - Notifications/Hooks
    
    /// Invalidates the intrinsicContentSize
    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.verticalSizeClass != previousTraitCollection?.verticalSizeClass || traitCollection.horizontalSizeClass != previousTraitCollection?.horizontalSizeClass {
            if shouldAutoUpdateMaxTextViewHeight {
                maxTextViewHeight = calculateMaxTextViewHeight()
            } else {
                invalidateIntrinsicContentSize()
            }
        }
    }
    
    /// Invalidates the intrinsicContentSize
    @objc
    open func orientationDidChange() {
        if shouldAutoUpdateMaxTextViewHeight {
            maxTextViewHeight = calculateMaxTextViewHeight()
        }
        invalidateIntrinsicContentSize()
    }
    
    /// Enables/Disables the sendButton based on the InputTextView's text being empty
    /// Calls each items `textViewDidChangeAction` method
    /// Calls the delegates `textViewTextDidChangeTo` method
    /// Invalidates the intrinsicContentSize
    @objc
    open func inputTextViewDidChange() {
        
        let trimmedText = inputTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if shouldManageSendButtonEnabledState {
            var isEnabled = !trimmedText.isEmpty
            if !isEnabled {
                // The images property is more resource intensive so only use it if needed
                isEnabled = inputTextView.images.count > 0
            }
            sendButton.isEnabled = isEnabled
        }
        
        // Capture change before iterating over the InputItem's
        let shouldInvalidateIntrinsicContentSize = requiredInputTextViewHeight != inputTextView.bounds.height
        
        items.forEach { $0.textViewDidChangeAction(with: self.inputTextView) }
        delegate?.messageInputBar(self, textViewTextDidChangeTo: trimmedText)
        
        if shouldInvalidateIntrinsicContentSize {
            // Prevent un-needed content size invalidation
            invalidateIntrinsicContentSize()
        }
        guard topViewHeightContraint?.constant ?? 0 > 0 else { return } // is searching
        keyword = trimmedText
    }
    
    /// Calls each items `keyboardEditingBeginsAction` method
    @objc
    open func inputTextViewDidBeginEditing() {
        items.forEach { $0.keyboardEditingBeginsAction() }
    }
    
    /// Calls each items `keyboardEditingEndsAction` method
    @objc
    open func inputTextViewDidEndEditing() {
        items.forEach { $0.keyboardEditingEndsAction() }
    }
    
    // MARK: - Plugins
    
    /// Reloads each of the plugins
    open func reloadPlugins() {
        plugins.forEach { $0.reloadData() }
    }
    
    /// Invalidates each of the plugins
    open func invalidatePlugins() {
        plugins.forEach { $0.invalidate() }
    }
    // MARK: - Actions
    private var keyword = "" {
        didSet {
            dataSource = keyword.isEmpty ? selectionItems : selectionItems.filter({ $0.uppercased().contains(keyword.uppercased()) })
            topCollectionView.reloadData()
            let newCollectionviewHeight = itemSize.height * CGFloat(max(1, min(dataSource.count, 3)))
            UIView.animate(withDuration: 0.0) {
                self.topViewHeightContraint?.isActive = true
                self.topViewHeightContraint?.constant = newCollectionviewHeight + self.topPadding
                self.invalidateIntrinsicContentSize()
                self.layoutIfNeeded()
            }
        }
    }
    
    private var dataSource = [String]()
    private let itemHeight: CGFloat = 50
    private var itemSize: CGSize = .zero
    private var topPadding: CGFloat = 35
    private var selectionItems = [String]() {
        didSet {
            topCollectionView.collectionViewLayout.invalidateLayout()
            (topCollectionView.collectionViewLayout as! UICollectionViewFlowLayout).scrollDirection = .vertical
            itemSize = CGSize(width: topCollectionView.frame.width, height: itemHeight)
            keyword = ""
        }
    }
    
    open func showTopView(with selections: [String]) {
        selectionItems = selections
        setRightStackViewWidthConstant(to: 0, animated: true)
        textViewPadding.right = 0
    }
    
    open func hideTopView() {
        selectionItems.removeAll()
        self.layoutIfNeeded()
        self.invalidateIntrinsicContentSize()
        self.keyword = ""
        self.topViewHeightContraint?.constant = 0
        setRightStackViewWidthConstant(to: 40, animated: true)
        textViewPadding.right = 9
    }
    // MARK: - User Actions
    
    /// Calls the delegates `didPressSendButtonWith` method
    /// Assumes that the InputTextView's text has been set to empty and calls `inputTextViewDidChange()`
    /// Invalidates each of the InputPlugins
    open func didSelectSendButton() {
        delegate?.messageInputBar(self, didPressSendButtonWith: inputTextView.text)
    }
}

extension MessageInputBar: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let result = dataSource[indexPath.row].dropFirst().dropFirst()
        delegate?.messageInputBar(self, topViewDidSelectedWith: String(result))
        hideTopView()
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        topCollectionView.backgroundView = dataSource.isEmpty ? noResultLabel : nil
        return dataSource.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return itemSize
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cel", for: indexPath) as! TextCollectionCell
        cell.setText(dataSource[indexPath.row], font: self.font)
        return cell
    }
}

class TextCollectionCell: UICollectionViewCell {
    override init(frame: CGRect) {
        super.init(frame: frame)
        initUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initUI()
    }
    
    var label: UILabel!
    
    func initUI() {
        label = UILabel()
        label.textColor = .black
        label.font = UIFont.systemFont(ofSize: 17)
        label.frame = bounds.inset(by: UIEdgeInsets(top: 5, left: 12, bottom: 5, right: 10))
        label.layer.borderColor = UIColor.lightGray.cgColor
        label.layer.cornerRadius = label.frame.size.height / 2.0
        label.textAlignment = .left
        addSubview(label)
    }
    
    func setText(_ text: String, font: UIFont?) {
        label.text = text
        if let font = font {
            label.font = font.withSize(16)
        }
    }
}
