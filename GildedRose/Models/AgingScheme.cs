// <auto-generated>
// ReSharper disable ConvertPropertyToExpressionBody
// ReSharper disable DoNotCallOverridableMethodsInConstructor
// ReSharper disable EmptyNamespace
// ReSharper disable InconsistentNaming
// ReSharper disable PartialMethodWithSinglePart
// ReSharper disable PartialTypeWithSinglePart
// ReSharper disable RedundantNameQualifier
// ReSharper disable RedundantOverridenMember
// ReSharper disable UseNameofExpression
// TargetFrameworkVersion = 4.6
#pragma warning disable 1591    //  Ignore "Missing XML Comment" warning


namespace GildedRose.Models
{

    // AgingScheme
    [System.CodeDom.Compiler.GeneratedCode("EF.Reverse.POCO.Generator", "2.37.1.0")]
    public class AgingScheme
    {
        public System.Guid AgingSchemeId { get; set; } // AgingSchemeId (Primary key)
        public string SchemeName { get; set; } // SchemeName (length: 256)
        public decimal DefaultIncrement { get; set; } // DefaultIncrement
        public decimal MaxQuality { get; set; } // MaxQuality
        public bool? ScrapOnExpiration { get; set; } // ScrapOnExpiration
        public System.Guid? ProductId { get; set; } // ProductId
        public System.DateTime LastUpdated { get; set; } // LastUpdated

        // Reverse navigation

        /// <summary>
        /// Child AgingThresholds where [AgingThreshold].[AgingSchemeId] point to this entity (FK_AgingThreshold_AgingScheme)
        /// </summary>
        public virtual System.Collections.Generic.ICollection<AgingThreshold> AgingThresholds { get; set; } // AgingThreshold.FK_AgingThreshold_AgingScheme
        /// <summary>
        /// Child Categories where [Category].[AgingSchemeId] point to this entity (FK_Category_AgingScheme)
        /// </summary>
        public virtual System.Collections.Generic.ICollection<Category> Categories { get; set; } // Category.FK_Category_AgingScheme

        // Foreign keys

        /// <summary>
        /// Parent Product pointed by [AgingScheme].([ProductId]) (FK_AgingScheme_Product)
        /// </summary>
        public virtual Product Product { get; set; } // FK_AgingScheme_Product

        public AgingScheme()
        {
            AgingSchemeId = System.Guid.NewGuid();
            LastUpdated = System.DateTime.UtcNow;
            AgingThresholds = new System.Collections.Generic.List<AgingThreshold>();
            Categories = new System.Collections.Generic.List<Category>();
        }
    }

}
// </auto-generated>