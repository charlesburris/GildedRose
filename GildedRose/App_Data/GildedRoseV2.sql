CREATE DATABASE GildedRoseCRB
GO
USE GildedRoseCRB
GO
/****** Object:  UserDefinedFunction [dbo].[getQualityAsOf]    Script Date: 9/16/2018 8:58:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Charles Burris
-- Create date: 2018-09-13
-- Description:	Calculate Remaining Quality
-- =============================================
CREATE FUNCTION [dbo].[getQualityAsOf] 
(
	@ReferenceDate DATE,
	@AsOfDate DATE,
	@SellIn INT,
	@InitialQuality INT,
	@AgingSchemeId uniqueidentifier,
	@DefaultIncrement DECIMAL(8,2),
	@MaxQuality DECIMAL(8,2),
	@ScrapOnExpiration bit
)
RETURNS INT
AS
BEGIN
  IF (@AgingSchemeId iS NULL)
    BEGIN
	  RETURN @InitialQuality
	END

  DECLARE @RetVal DECIMAL(8,2) = 0.00
  DECLARE @DaysDiff INT = (SELECT DATEDIFF(DAY, @ReferenceDate, @AsOfDate))
  IF (@DaysDiff = 0)
    BEGIN
	  RETURN @InitialQuality
	END
  
  --Process non-Threshold Products and RETURN (Simplest calculation)
  IF ((SELECT COUNT(1) FROM dbo.AgingThreshold t WHERE t.AgingSchemeId = @AgingSchemeId) = 0)
    BEGIN
	  --DO THE MATH, check limits
	  SET @RetVal = (SELECT (@DaysDiff * @DefaultIncrement) + @InitialQuality) 
	END
  ELSE
    BEGIN
	  DECLARE @RemainingDays INT = (SELECT @SellIn - @DaysDiff)
	  DECLARE @IncrementRate DECIMAL(8,2) = (SELECT TOP 1 IncrementRate 
											FROM dbo.AgingThreshold a 
											WHERE a.AgingSchemeId = @AgingSchemeId
											  AND @RemainingDays <= a.DaysPrior)
	  IF (@IncrementRate IS NULL OR @IncrementRate = 0.00)
        SET @IncrementRate = (SELECT @DefaultIncrement) 
      SET @RetVal = (SELECT (@DaysDiff * @IncrementRate) + @InitialQuality) 
  END
	IF (@RetVal > @MaxQuality)
	  SET @RetVal = (SELECT @MaxQuality)
	IF (@RetVal < 0)
	  SET @RetVal = 0

  RETURN ROUND(@RetVal, 0)

END













GO
/****** Object:  UserDefinedFunction [dbo].[getRemainingDays]    Script Date: 9/16/2018 8:58:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




-- =============================================
-- Author:		Charles Burris
-- Create date: 2018-09-13
-- Description:	Calculate Remaining Days based on SellIn
-- =============================================
CREATE FUNCTION [dbo].[getRemainingDays] 
(
	@ReferenceDate DATE,
	@AsOfDate DATE,
	@SellIn INT,
	@AgingSchemeId uniqueidentifier,
	@ScrapOnExpiration bit
)
RETURNS INT
AS
BEGIN
  DECLARE @RetVal DECIMAL(8,2) = 0.00
  DECLARE @DaysDiff INT = (SELECT DATEDIFF(DAY, @ReferenceDate, @AsOfDate))

  IF (@DaysDiff = 0)
    RETURN @SellIn

  IF (@AgingSchemeId iS NULL)
	  RETURN @SellIn

  /*
  --Process non-Threshold Products and RETURN (Simplest calculation)
  IF ((SELECT COUNT(1) FROM dbo.AgingThreshold t WHERE t.AgingSchemeId = @AgingSchemeId) = 0)
    BEGIN
	  --DO THE MATH, check limits
	  SET @RetVal = (SELECT (@DaysDiff * @DefaultIncrement) + @InitialQuality) 
	END
  ELSE
    BEGIN
	  DECLARE @RemainingDays INT = (SELECT @SellIn - @DaysDiff)
	  DECLARE @IncrementRate DECIMAL(8,2) = (SELECT TOP 1 IncrementRate 
											FROM dbo.AgingThreshold a 
											WHERE a.AgingSchemeId = @AgingSchemeId
											  AND @RemainingDays <= a.DaysPrior)
	  IF (@IncrementRate IS NULL OR @IncrementRate = 0.00)
        SET @IncrementRate = (SELECT @DefaultIncrement) 
      SET @RetVal = (SELECT (@DaysDiff * @IncrementRate) + @InitialQuality) 
  END
	IF (@RetVal > @MaxQuality)
	  SET @RetVal = (SELECT @MaxQuality)
	IF (@RetVal < 0)
	  SET @RetVal = 0
  */
  RETURN (SELECT @SellIn - @DaysDiff)
  --RETURN ROUND(@RetVal, 0)

END













GO
/****** Object:  Table [dbo].[AgingScheme]    Script Date: 9/16/2018 8:58:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AgingScheme](
	[AgingSchemeId] [uniqueidentifier] NOT NULL,
	[SchemeName] [varchar](256) NOT NULL,
	[DefaultIncrement] [decimal](8, 2) NOT NULL,
	[MaxQuality] [decimal](8, 2) NOT NULL,
	[ScrapOnExpiration] [bit] NULL,
	[ProductId] [uniqueidentifier] NULL,
	[LastUpdated] [datetime] NOT NULL,
 CONSTRAINT [PK_AgingSchemeId] PRIMARY KEY CLUSTERED 
(
	[AgingSchemeId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[AgingThreshold]    Script Date: 9/16/2018 8:58:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AgingThreshold](
	[AgingThresholdId] [uniqueidentifier] NOT NULL,
	[AgingSchemeId] [uniqueidentifier] NOT NULL,
	[ThresholdName] [varchar](256) NOT NULL,
	[DaysPrior] [int] NOT NULL,
	[IncrementRate] [decimal](8, 2) NOT NULL,
	[LastUpdated] [datetime] NOT NULL,
 CONSTRAINT [PK_AgingThresholdId] PRIMARY KEY CLUSTERED 
(
	[AgingThresholdId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Category]    Script Date: 9/16/2018 8:58:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Category](
	[CategoryId] [uniqueidentifier] NOT NULL,
	[AgingSchemeId] [uniqueidentifier] NULL,
	[CategoryName] [varchar](256) NOT NULL,
	[LastUpdated] [datetime] NOT NULL,
 CONSTRAINT [PK_CategoryId] PRIMARY KEY CLUSTERED 
(
	[CategoryId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[InventoryCsvImport]    Script Date: 9/16/2018 8:58:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[InventoryCsvImport](
	[ProductName] [nvarchar](150) NOT NULL,
	[ProductCategory] [nvarchar](150) NOT NULL,
	[SellInDays] [int] NOT NULL,
	[Quality] [int] NOT NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Product]    Script Date: 9/16/2018 8:58:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Product](
	[ProductId] [uniqueidentifier] NOT NULL,
	[CategoryId] [uniqueidentifier] NOT NULL,
	[ProductName] [varchar](256) NOT NULL,
	[SellIn] [int] NULL,
	[InitialQuality] [int] NULL,
	[ReceiptDate] [date] NULL,
	[LastUpdated] [datetime] NOT NULL,
 CONSTRAINT [PK_InventoryId] PRIMARY KEY CLUSTERED 
(
	[ProductId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  View [dbo].[vProductCategoryAging]    Script Date: 9/16/2018 8:58:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[vProductCategoryAging]
AS
SELECT p.ProductId,
	   p.ProductName,
	   p.SellIn,
	   p.InitialQuality,
	   c.CategoryName,
	   (CASE WHEN ap.ProductId IS NULL THEN a.AgingSchemeId ELSE ap.AgingSchemeId END) AS AgingSchemeId, 
	   (CASE WHEN ap.ProductId IS NULL THEN a.SchemeName ELSE ap.SchemeName END) AS SchemeName,
	   (CASE WHEN ap.ProductId IS NULL THEN a.DefaultIncrement ELSE ap.DefaultIncrement END) AS DefaultIncrement, 
       (CASE WHEN ap.ProductId IS NULL THEN a.MaxQuality ELSE ap.MaxQuality END) AS MaxQuality,
	   (CASE WHEN ap.ProductId IS NULL THEN a.ScrapOnExpiration ELSE ap.ScrapOnExpiration END) AS ScrapOnExpiration
FROM     dbo.Product AS p INNER JOIN
                  dbo.Category AS c ON c.CategoryId = p.CategoryId LEFT OUTER JOIN
                  dbo.AgingScheme AS a ON a.AgingSchemeId = c.AgingSchemeId LEFT OUTER JOIN
                  dbo.AgingScheme AS ap ON ap.ProductId = p.ProductId
GO
INSERT [dbo].[AgingScheme] ([AgingSchemeId], [SchemeName], [DefaultIncrement], [MaxQuality], [ScrapOnExpiration], [ProductId], [LastUpdated]) VALUES (N'05e5bf8e-ee30-427f-beb7-5beda115a047', N'Standard decrease', CAST(-1.00 AS Decimal(8, 2)), CAST(50.00 AS Decimal(8, 2)), 0, NULL, CAST(N'2018-09-15T02:37:21.733' AS DateTime))
INSERT [dbo].[AgingScheme] ([AgingSchemeId], [SchemeName], [DefaultIncrement], [MaxQuality], [ScrapOnExpiration], [ProductId], [LastUpdated]) VALUES (N'c744570d-f764-4db2-9a58-d65b1059ffc6', N'Backstage Passes', CAST(1.00 AS Decimal(8, 2)), CAST(0.00 AS Decimal(8, 2)), 1, NULL, CAST(N'2018-09-15T18:15:15.213' AS DateTime))
INSERT [dbo].[AgingScheme] ([AgingSchemeId], [SchemeName], [DefaultIncrement], [MaxQuality], [ScrapOnExpiration], [ProductId], [LastUpdated]) VALUES (N'f3870093-2036-418b-8882-e212b7bd30c7', N'Brie', CAST(1.00 AS Decimal(8, 2)), CAST(50.00 AS Decimal(8, 2)), 0, N'9497bcea-13b4-4989-bf68-49913353da7d', CAST(N'2018-09-15T18:09:34.403' AS DateTime))
INSERT [dbo].[AgingScheme] ([AgingSchemeId], [SchemeName], [DefaultIncrement], [MaxQuality], [ScrapOnExpiration], [ProductId], [LastUpdated]) VALUES (N'2942eed7-58ec-46c2-8ba2-e55e3f00a3e8', N'Double decrease (ex: Conjured)', CAST(-2.00 AS Decimal(8, 2)), CAST(50.00 AS Decimal(8, 2)), 0, NULL, CAST(N'2018-09-15T18:23:56.870' AS DateTime))
INSERT [dbo].[AgingThreshold] ([AgingThresholdId], [AgingSchemeId], [ThresholdName], [DaysPrior], [IncrementRate], [LastUpdated]) VALUES (N'9b4da309-1e88-48dd-854f-6d705a2b72b0', N'05e5bf8e-ee30-427f-beb7-5beda115a047', N'Double decrease after 0', -1, CAST(-2.00 AS Decimal(8, 2)), CAST(N'2018-09-15T18:06:24.610' AS DateTime))
INSERT [dbo].[AgingThreshold] ([AgingThresholdId], [AgingSchemeId], [ThresholdName], [DaysPrior], [IncrementRate], [LastUpdated]) VALUES (N'bc78edf3-8709-47d6-a679-b43b841ae1d9', N'c744570d-f764-4db2-9a58-d65b1059ffc6', N'Double increase 10 days', 10, CAST(2.00 AS Decimal(8, 2)), CAST(N'2018-09-15T18:18:32.163' AS DateTime))
INSERT [dbo].[AgingThreshold] ([AgingThresholdId], [AgingSchemeId], [ThresholdName], [DaysPrior], [IncrementRate], [LastUpdated]) VALUES (N'5981cbeb-a6f7-4173-8f3f-b6ad5e2ed1cb', N'c744570d-f764-4db2-9a58-d65b1059ffc6', N'Triple increase 5 days', 5, CAST(3.00 AS Decimal(8, 2)), CAST(N'2018-09-15T18:19:05.283' AS DateTime))
INSERT [dbo].[Category] ([CategoryId], [AgingSchemeId], [CategoryName], [LastUpdated]) VALUES (N'4e8484a0-91d4-41ba-9642-031cf921a16f', N'05e5bf8e-ee30-427f-beb7-5beda115a047', N'Armor', CAST(N'2018-09-13T02:28:38.313' AS DateTime))
INSERT [dbo].[Category] ([CategoryId], [AgingSchemeId], [CategoryName], [LastUpdated]) VALUES (N'aea8bb43-354a-454b-b13e-0c44b106655b', N'05e5bf8e-ee30-427f-beb7-5beda115a047', N'Potion', CAST(N'2018-09-13T02:28:38.313' AS DateTime))
INSERT [dbo].[Category] ([CategoryId], [AgingSchemeId], [CategoryName], [LastUpdated]) VALUES (N'ec849ad3-4ff0-4c94-9882-0f2e5c80d741', NULL, N'Sulfuras', CAST(N'2018-09-13T02:28:38.313' AS DateTime))
INSERT [dbo].[Category] ([CategoryId], [AgingSchemeId], [CategoryName], [LastUpdated]) VALUES (N'98b3a3f7-d907-44f4-ab01-261422ad2599', N'2942eed7-58ec-46c2-8ba2-e55e3f00a3e8', N'Conjured', CAST(N'2018-09-13T02:28:38.313' AS DateTime))
INSERT [dbo].[Category] ([CategoryId], [AgingSchemeId], [CategoryName], [LastUpdated]) VALUES (N'326061bb-401f-4021-9f3b-a400c7b0b269', N'05e5bf8e-ee30-427f-beb7-5beda115a047', N'Food', CAST(N'2018-09-13T02:28:38.313' AS DateTime))
INSERT [dbo].[Category] ([CategoryId], [AgingSchemeId], [CategoryName], [LastUpdated]) VALUES (N'88c9cf7f-611b-4894-97e3-cb46b3edcfc8', N'05e5bf8e-ee30-427f-beb7-5beda115a047', N'Weapon', CAST(N'2018-09-13T02:28:38.313' AS DateTime))
INSERT [dbo].[Category] ([CategoryId], [AgingSchemeId], [CategoryName], [LastUpdated]) VALUES (N'36772581-d3f5-44ae-8fb1-d3aca7c97dd2', N'c744570d-f764-4db2-9a58-d65b1059ffc6', N'Backstage Passes', CAST(N'2018-09-13T02:28:38.313' AS DateTime))
INSERT [dbo].[Category] ([CategoryId], [AgingSchemeId], [CategoryName], [LastUpdated]) VALUES (N'bfcbae84-6b0f-48b0-9d22-eb346fbabbe7', N'05e5bf8e-ee30-427f-beb7-5beda115a047', N'Misc', CAST(N'2018-09-13T02:28:38.313' AS DateTime))
INSERT [dbo].[InventoryCsvImport] ([ProductName], [ProductCategory], [SellInDays], [Quality]) VALUES (N'Axe', N'Weapon', 40, 50)
INSERT [dbo].[InventoryCsvImport] ([ProductName], [ProductCategory], [SellInDays], [Quality]) VALUES (N'Halberd', N'Weapon', 60, 40)
INSERT [dbo].[InventoryCsvImport] ([ProductName], [ProductCategory], [SellInDays], [Quality]) VALUES (N'Aged Brie', N'Food', 50, 10)
INSERT [dbo].[InventoryCsvImport] ([ProductName], [ProductCategory], [SellInDays], [Quality]) VALUES (N'Aged Milk', N'Food', 20, 20)
INSERT [dbo].[InventoryCsvImport] ([ProductName], [ProductCategory], [SellInDays], [Quality]) VALUES (N'Mutton', N'Food', 10, 10)
INSERT [dbo].[InventoryCsvImport] ([ProductName], [ProductCategory], [SellInDays], [Quality]) VALUES (N'Hand of Ragnaros', N'Sulfuras', 80, 80)
INSERT [dbo].[InventoryCsvImport] ([ProductName], [ProductCategory], [SellInDays], [Quality]) VALUES (N'I am Murloc', N'Backstage Passes', 20, 10)
INSERT [dbo].[InventoryCsvImport] ([ProductName], [ProductCategory], [SellInDays], [Quality]) VALUES (N'Raging Ogre', N'Backstage Passes', 10, 10)
INSERT [dbo].[InventoryCsvImport] ([ProductName], [ProductCategory], [SellInDays], [Quality]) VALUES (N'Giant Slayer', N'Conjured', 15, 50)
INSERT [dbo].[InventoryCsvImport] ([ProductName], [ProductCategory], [SellInDays], [Quality]) VALUES (N'Storm Hammer', N'Conjured', 20, 50)
INSERT [dbo].[InventoryCsvImport] ([ProductName], [ProductCategory], [SellInDays], [Quality]) VALUES (N'Belt of Giant Strength', N'Conjured', 20, 40)
INSERT [dbo].[InventoryCsvImport] ([ProductName], [ProductCategory], [SellInDays], [Quality]) VALUES (N'Cheese', N'Food', 5, 5)
INSERT [dbo].[InventoryCsvImport] ([ProductName], [ProductCategory], [SellInDays], [Quality]) VALUES (N'Potion of Healing', N'Potion', 10, 10)
INSERT [dbo].[InventoryCsvImport] ([ProductName], [ProductCategory], [SellInDays], [Quality]) VALUES (N'Bag of Holding', N'Misc', 10, 50)
INSERT [dbo].[InventoryCsvImport] ([ProductName], [ProductCategory], [SellInDays], [Quality]) VALUES (N'TAFKAL80ETC Concert', N'Backstage Passes', 15, 20)
INSERT [dbo].[InventoryCsvImport] ([ProductName], [ProductCategory], [SellInDays], [Quality]) VALUES (N'Elixir of the Mongoose', N'Potion', 5, 7)
INSERT [dbo].[InventoryCsvImport] ([ProductName], [ProductCategory], [SellInDays], [Quality]) VALUES (N'+5 Dexterity Vest', N'Armor', 10, 20)
INSERT [dbo].[InventoryCsvImport] ([ProductName], [ProductCategory], [SellInDays], [Quality]) VALUES (N'Full Plate Mail', N'Armor', 50, 50)
INSERT [dbo].[InventoryCsvImport] ([ProductName], [ProductCategory], [SellInDays], [Quality]) VALUES (N'Wooden Shield', N'Armor', 10, 30)
INSERT [dbo].[Product] ([ProductId], [CategoryId], [ProductName], [SellIn], [InitialQuality], [ReceiptDate], [LastUpdated]) VALUES (N'8a69d32d-d271-45e9-b7b1-14f94a3ed141', N'4e8484a0-91d4-41ba-9642-031cf921a16f', N'Wooden Shield', 10, 30, CAST(N'2018-09-15' AS Date), CAST(N'2018-09-15T20:35:53.143' AS DateTime))
INSERT [dbo].[Product] ([ProductId], [CategoryId], [ProductName], [SellIn], [InitialQuality], [ReceiptDate], [LastUpdated]) VALUES (N'90832259-66df-48ae-bfe9-1cece5cd7d3b', N'88c9cf7f-611b-4894-97e3-cb46b3edcfc8', N'Axe', 40, 50, CAST(N'2018-09-15' AS Date), CAST(N'2018-09-15T20:35:53.143' AS DateTime))
INSERT [dbo].[Product] ([ProductId], [CategoryId], [ProductName], [SellIn], [InitialQuality], [ReceiptDate], [LastUpdated]) VALUES (N'f83896a2-4a5a-47be-9714-26536d7fbf7d', N'326061bb-401f-4021-9f3b-a400c7b0b269', N'Aged Milk', 20, 20, CAST(N'2018-09-15' AS Date), CAST(N'2018-09-15T20:35:53.143' AS DateTime))
INSERT [dbo].[Product] ([ProductId], [CategoryId], [ProductName], [SellIn], [InitialQuality], [ReceiptDate], [LastUpdated]) VALUES (N'40395588-d693-4ffe-9065-421e99fccdc0', N'ec849ad3-4ff0-4c94-9882-0f2e5c80d741', N'Hand of Ragnaros', 80, 80, CAST(N'2018-09-15' AS Date), CAST(N'2018-09-15T20:35:53.143' AS DateTime))
INSERT [dbo].[Product] ([ProductId], [CategoryId], [ProductName], [SellIn], [InitialQuality], [ReceiptDate], [LastUpdated]) VALUES (N'81934787-c394-4d95-b7fb-45a8527999a4', N'98b3a3f7-d907-44f4-ab01-261422ad2599', N'Storm Hammer', 20, 50, CAST(N'2018-09-15' AS Date), CAST(N'2018-09-15T20:35:53.143' AS DateTime))
INSERT [dbo].[Product] ([ProductId], [CategoryId], [ProductName], [SellIn], [InitialQuality], [ReceiptDate], [LastUpdated]) VALUES (N'9497bcea-13b4-4989-bf68-49913353da7d', N'326061bb-401f-4021-9f3b-a400c7b0b269', N'Aged Brie', 50, 10, CAST(N'2018-09-15' AS Date), CAST(N'2018-09-15T20:35:53.143' AS DateTime))
INSERT [dbo].[Product] ([ProductId], [CategoryId], [ProductName], [SellIn], [InitialQuality], [ReceiptDate], [LastUpdated]) VALUES (N'3df83bcd-a93f-460a-a775-4ff2403d428f', N'98b3a3f7-d907-44f4-ab01-261422ad2599', N'Belt of Giant Strength', 20, 40, CAST(N'2018-09-15' AS Date), CAST(N'2018-09-15T20:35:53.143' AS DateTime))
INSERT [dbo].[Product] ([ProductId], [CategoryId], [ProductName], [SellIn], [InitialQuality], [ReceiptDate], [LastUpdated]) VALUES (N'c17e164f-52b3-4dea-881c-5043140aeae8', N'36772581-d3f5-44ae-8fb1-d3aca7c97dd2', N'Raging Ogre', 10, 10, CAST(N'2018-09-15' AS Date), CAST(N'2018-09-15T20:35:53.143' AS DateTime))
INSERT [dbo].[Product] ([ProductId], [CategoryId], [ProductName], [SellIn], [InitialQuality], [ReceiptDate], [LastUpdated]) VALUES (N'2e2ca297-fe11-4033-ba17-72e121f80682', N'88c9cf7f-611b-4894-97e3-cb46b3edcfc8', N'Halberd', 60, 40, CAST(N'2018-09-15' AS Date), CAST(N'2018-09-15T20:35:53.143' AS DateTime))
INSERT [dbo].[Product] ([ProductId], [CategoryId], [ProductName], [SellIn], [InitialQuality], [ReceiptDate], [LastUpdated]) VALUES (N'fe625564-b2be-4038-bbb6-7deb0504ece2', N'36772581-d3f5-44ae-8fb1-d3aca7c97dd2', N'TAFKAL80ETC Concert', 15, 20, CAST(N'2018-09-15' AS Date), CAST(N'2018-09-15T20:35:53.143' AS DateTime))
INSERT [dbo].[Product] ([ProductId], [CategoryId], [ProductName], [SellIn], [InitialQuality], [ReceiptDate], [LastUpdated]) VALUES (N'4bb88576-3b54-48cf-8eea-84205aed9307', N'4e8484a0-91d4-41ba-9642-031cf921a16f', N'Full Plate Mail', 50, 50, CAST(N'2018-09-15' AS Date), CAST(N'2018-09-15T20:35:53.143' AS DateTime))
INSERT [dbo].[Product] ([ProductId], [CategoryId], [ProductName], [SellIn], [InitialQuality], [ReceiptDate], [LastUpdated]) VALUES (N'82de2115-e179-46ba-aa4d-84b939645456', N'326061bb-401f-4021-9f3b-a400c7b0b269', N'Cheese', 5, 5, CAST(N'2018-09-15' AS Date), CAST(N'2018-09-15T20:35:53.143' AS DateTime))
INSERT [dbo].[Product] ([ProductId], [CategoryId], [ProductName], [SellIn], [InitialQuality], [ReceiptDate], [LastUpdated]) VALUES (N'7e27a704-8174-44fa-b72f-87da5de3747b', N'aea8bb43-354a-454b-b13e-0c44b106655b', N'Potion of Healing', 10, 10, CAST(N'2018-09-15' AS Date), CAST(N'2018-09-15T20:35:53.143' AS DateTime))
INSERT [dbo].[Product] ([ProductId], [CategoryId], [ProductName], [SellIn], [InitialQuality], [ReceiptDate], [LastUpdated]) VALUES (N'376adc04-720b-4de2-84bc-8de684743017', N'4e8484a0-91d4-41ba-9642-031cf921a16f', N'+5 Dexterity Vest', 10, 20, CAST(N'2018-09-15' AS Date), CAST(N'2018-09-15T20:35:53.143' AS DateTime))
INSERT [dbo].[Product] ([ProductId], [CategoryId], [ProductName], [SellIn], [InitialQuality], [ReceiptDate], [LastUpdated]) VALUES (N'6c519aa1-a78b-40b8-9e03-bb9b5d68cb4a', N'98b3a3f7-d907-44f4-ab01-261422ad2599', N'Giant Slayer', 15, 50, CAST(N'2018-09-15' AS Date), CAST(N'2018-09-15T20:35:53.143' AS DateTime))
INSERT [dbo].[Product] ([ProductId], [CategoryId], [ProductName], [SellIn], [InitialQuality], [ReceiptDate], [LastUpdated]) VALUES (N'4a906338-b396-42b6-ac95-c042cee78d80', N'bfcbae84-6b0f-48b0-9d22-eb346fbabbe7', N'Bag of Holding', 10, 50, CAST(N'2018-09-15' AS Date), CAST(N'2018-09-15T20:35:53.143' AS DateTime))
INSERT [dbo].[Product] ([ProductId], [CategoryId], [ProductName], [SellIn], [InitialQuality], [ReceiptDate], [LastUpdated]) VALUES (N'a8c348a7-2a2f-4dd8-bd0c-e0b5bc1e8160', N'aea8bb43-354a-454b-b13e-0c44b106655b', N'Elixir of the Mongoose', 5, 7, CAST(N'2018-09-15' AS Date), CAST(N'2018-09-15T20:35:53.143' AS DateTime))
INSERT [dbo].[Product] ([ProductId], [CategoryId], [ProductName], [SellIn], [InitialQuality], [ReceiptDate], [LastUpdated]) VALUES (N'7e49c61f-d2f4-43c3-ae8d-e720f58ec7e3', N'326061bb-401f-4021-9f3b-a400c7b0b269', N'Mutton', 10, 10, CAST(N'2018-09-15' AS Date), CAST(N'2018-09-15T20:35:53.143' AS DateTime))
INSERT [dbo].[Product] ([ProductId], [CategoryId], [ProductName], [SellIn], [InitialQuality], [ReceiptDate], [LastUpdated]) VALUES (N'849fdd46-9235-4deb-b443-ed775f37e505', N'36772581-d3f5-44ae-8fb1-d3aca7c97dd2', N'I am Murloc', 20, 10, CAST(N'2018-09-15' AS Date), CAST(N'2018-09-15T20:35:53.143' AS DateTime))
ALTER TABLE [dbo].[AgingScheme] ADD  CONSTRAINT [DF_AgingScheme_AgingSchemeId]  DEFAULT (newid()) FOR [AgingSchemeId]
GO
ALTER TABLE [dbo].[AgingScheme] ADD  CONSTRAINT [DF_AgingScheme_LastUpdated]  DEFAULT (getutcdate()) FOR [LastUpdated]
GO
ALTER TABLE [dbo].[AgingThreshold] ADD  CONSTRAINT [DF_AgingThreshold_AgingThresholdId]  DEFAULT (newid()) FOR [AgingThresholdId]
GO
ALTER TABLE [dbo].[AgingThreshold] ADD  CONSTRAINT [DF_AgingThreshold_LastUpdated]  DEFAULT (getutcdate()) FOR [LastUpdated]
GO
ALTER TABLE [dbo].[Category] ADD  CONSTRAINT [DF_Category_CategoryId]  DEFAULT (newid()) FOR [CategoryId]
GO
ALTER TABLE [dbo].[Category] ADD  CONSTRAINT [DF_Category_LastUpdated]  DEFAULT (getutcdate()) FOR [LastUpdated]
GO
ALTER TABLE [dbo].[Product] ADD  CONSTRAINT [DF_Inventory_InventoryId]  DEFAULT (newid()) FOR [ProductId]
GO
ALTER TABLE [dbo].[AgingScheme]  WITH NOCHECK ADD  CONSTRAINT [FK_AgingScheme_Product] FOREIGN KEY([ProductId])
REFERENCES [dbo].[Product] ([ProductId])
GO
ALTER TABLE [dbo].[AgingScheme] NOCHECK CONSTRAINT [FK_AgingScheme_Product]
GO
ALTER TABLE [dbo].[AgingThreshold]  WITH CHECK ADD  CONSTRAINT [FK_AgingThreshold_AgingScheme] FOREIGN KEY([AgingSchemeId])
REFERENCES [dbo].[AgingScheme] ([AgingSchemeId])
GO
ALTER TABLE [dbo].[AgingThreshold] CHECK CONSTRAINT [FK_AgingThreshold_AgingScheme]
GO
ALTER TABLE [dbo].[Category]  WITH CHECK ADD  CONSTRAINT [FK_Category_AgingScheme] FOREIGN KEY([AgingSchemeId])
REFERENCES [dbo].[AgingScheme] ([AgingSchemeId])
GO
ALTER TABLE [dbo].[Category] CHECK CONSTRAINT [FK_Category_AgingScheme]
GO
ALTER TABLE [dbo].[Product]  WITH CHECK ADD  CONSTRAINT [FK_Product_Category] FOREIGN KEY([CategoryId])
REFERENCES [dbo].[Category] ([CategoryId])
GO
ALTER TABLE [dbo].[Product] CHECK CONSTRAINT [FK_Product_Category]
GO
/****** Object:  StoredProcedure [dbo].[ImportAgingCSV]    Script Date: 9/16/2018 8:58:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		Charles Burris
-- Create date: 2018-09-12
-- Description:	Import/Upload Inventory Aging file
-- =============================================
CREATE PROCEDURE [dbo].[ImportAgingCSV] 
	@ReceiptDate DATE 
AS
BEGIN
	SET NOCOUNT ON;

INSERT INTO [dbo].[Category]
           ([CategoryId]
           ,[AgingSchemeId]
           ,[CategoryName]
           ,[LastUpdated])
      SELECT NEWID(),
	  NULL,
	  x.ProductCategory,
	  GETUTCDATE()
	  FROM dbo.InventoryCsvImport x WHERE x.ProductCategory NOT IN (SELECT DISTINCT CategoryName from dbo.Category)

--TODO - check for update to existing
INSERT INTO [dbo].[Product]
           ([ProductId]
           ,[CategoryId]
           ,[ProductName]
           ,[SellIn]
           ,[InitialQuality]
           ,[ReceiptDate]
		   ,LastUpdated)
     SELECT NEWID(),
			(SELECT CategoryId from dbo.Category cat where x.ProductCategory = cat.CategoryName),
			x.ProductName,
			x.SellInDays,
			x.Quality,
			GETUTCDATE(),
			GETUTCDATE()
	FROM dbo.InventoryCsvImport x WHERE X.ProductName NOT IN (SELECT DISTINCT ProductName FROM dbo.Product)

END
GO
/****** Object:  StoredProcedure [dbo].[ProductAgingList]    Script Date: 9/16/2018 8:58:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


--region [dbo].[ActivityReport]

------------------------------------------------------------------------------------------------------------------------
-- Procedure Name: [dbo].[ProductAgeList]
-- Date Generated: Thursday, September 13, 2018
-- Author: Charles Burris
------------------------------------------------------------------------------------------------------------------------

CREATE  PROCEDURE [dbo].[ProductAgingList]
@ReferenceDate DATE,
@AsOfDate DATE,
@ProductId uniqueidentifier

AS

set quoted_identifier OFF
SET NOCOUNT ON

IF (@ReferenceDate IS NULL)
  BEGIN
    SET @ReferenceDate = (SELECT GETUTCDATE())
  END

SELECT vP.ProductId,
	   vP.ProductName, 
	   vP.CategoryName,
	   vP.SchemeName,
	   @ReferenceDate AS ReceiptDate,
	   p.SellIn,
	   p.InitialQuality,
	   dbo.getQualityAsOf(@ReferenceDate, @AsOfDate, p.SellIn, p.InitialQuality, vP.AgingSchemeId,
	    vP.DefaultIncrement, vP.MaxQuality, vP.ScrapOnExpiration) AS RemainingQuality,
	   dbo.getRemainingDays(@ReferenceDate, @AsOfDate, p.SellIn, vP.AgingSchemeId,
	     vP.ScrapOnExpiration) AS RemainingDays
 FROM dbo.vProductCategoryAging vP
     INNER JOIN dbo.Product p on p.ProductId = vP.ProductId
	 ORDER BY vP.ProductName

GO
